import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/crypto/crypto_identity_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/security/biometric_service.dart';
import 'package:hanbova_app/core/security/wallet_backup_store.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/security/application/restore_wallet_controller.dart';
import 'package:http/http.dart' as http;

const validMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

const aliceContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

final restoreActiveContextProvider =
    StateProvider<WalletContextKey?>((ref) => aliceContext);

final class FixedAuthGateway implements LocalAuthGateway {
  final bool result;

  const FixedAuthGateway(this.result);

  @override
  Future<bool> canCheckBiometrics() async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate(String reason) async => result;
}

final class FakeBackupStore implements WalletBackupStore {
  final List<WalletContextKey> confirmedContexts = [];

  @override
  Future<bool> isConfirmed(WalletContextKey context) async => false;

  @override
  Future<void> setConfirmed(WalletContextKey context, bool value) async {
    if (value) confirmedContexts.add(context);
  }
}

final class FakeWallet implements CashuWalletService {
  final bool balanceFails;
  int getBalanceCalls = 0;

  FakeWallet({this.balanceFails = false});

  @override
  Future<CashuWalletBalance> getBalance() async {
    getBalanceCalls += 1;
    if (balanceFails) throw StateError('wallet rebuild failed');
    return const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeCryptoNotifier extends CryptoIdentityNotifier {
  final WalletCryptoIdentity identity;
  final void Function()? duringRestore;
  int publicationFailuresBeforeSuccess;
  int restoreCalls = 0;
  int requireIdentityCalls = 0;
  int publicationCalls = 0;

  FakeCryptoNotifier({
    required this.identity,
    this.duringRestore,
    this.publicationFailuresBeforeSuccess = 0,
  });

  @override
  Future<WalletCryptoIdentity?> build() async => null;

  @override
  Future<WalletCryptoIdentity> restoreFromMnemonic({
    required String mnemonic,
  }) async {
    restoreCalls += 1;
    duringRestore?.call();
    return identity;
  }

  @override
  Future<WalletCryptoIdentity> requireIdentity() async {
    requireIdentityCalls += 1;
    return identity;
  }

  @override
  Future<void> publishPublicKeys({
    required ApiClient apiClient,
    required WalletCryptoIdentity identity,
    String? walletEnvironment,
  }) async {
    publicationCalls += 1;
    if (publicationFailuresBeforeSuccess > 0) {
      publicationFailuresBeforeSuccess -= 1;
      throw StateError('offline');
    }
  }
}

final class RestoreHarness {
  final ProviderContainer container;
  final FakeCryptoNotifier crypto;
  final FakeBackupStore backupStore;
  final FakeWallet? wallet;

  const RestoreHarness({
    required this.container,
    required this.crypto,
    required this.backupStore,
    required this.wallet,
  });

  RestoreWalletController get controller =>
      container.read(restoreWalletControllerProvider);
}

Future<WalletCryptoIdentity> identityFor(WalletContextKey context) async {
  return WalletCryptoIdentity(
    context: context,
    protectedPaymentPubkey:
        '02abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
    transportEncryptionPubkey:
        'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
    transportKeyPair: await X25519().newKeyPair(),
    protectedPaymentPrivkeyHex:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    mnemonic: validMnemonic,
    walletSeedHex:
        '0000000000000000000000000000000000000000000000000000000000000000',
  );
}

Future<RestoreHarness> restoreHarness({
  WalletContextKey? activeContext = aliceContext,
  bool authResult = true,
  bool walletUnavailable = false,
  bool walletBalanceFails = false,
  bool changeContextDuringRestore = false,
  int publicationFailuresBeforeSuccess = 0,
}) async {
  final identity = await identityFor(aliceContext);
  late ProviderContainer container;
  final crypto = FakeCryptoNotifier(
    identity: identity,
    publicationFailuresBeforeSuccess: publicationFailuresBeforeSuccess,
    duringRestore: changeContextDuringRestore
        ? () {
            container.read(restoreActiveContextProvider.notifier).state = null;
          }
        : null,
  );
  final backupStore = FakeBackupStore();
  final wallet =
      walletUnavailable ? null : FakeWallet(balanceFails: walletBalanceFails);
  container = ProviderContainer(overrides: [
    restoreActiveContextProvider.overrideWith((ref) => activeContext),
    activeWalletContextKeyProvider.overrideWith(
      (ref) => ref.watch(restoreActiveContextProvider),
    ),
    biometricServiceProvider.overrideWithValue(
      BiometricService(gateway: FixedAuthGateway(authResult)),
    ),
    cryptoIdentityProvider.overrideWith(() => crypto),
    walletBackupStoreProvider.overrideWithValue(backupStore),
    cashuWalletServiceProvider.overrideWithValue(wallet),
    apiClientProvider.overrideWithValue(
      ApiClient(baseUrl: 'https://example.test', httpClient: http.Client()),
    ),
  ]);
  return RestoreHarness(
    container: container,
    crypto: crypto,
    backupStore: backupStore,
    wallet: wallet,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restore refuses unauthenticated context before touching identity',
      () async {
    final harness = await restoreHarness(activeContext: null);
    addTearDown(harness.container.dispose);

    await expectLater(
      harness.controller.restore(validMnemonic),
      throwsA(
        isA<RestoreWalletFailure>().having(
          (failure) => failure.code,
          'code',
          'authentication_required',
        ),
      ),
    );
    expect(harness.crypto.restoreCalls, 0);
  });

  test(
      'restore reports sync pending after local success and publication failure',
      () async {
    final harness = await restoreHarness(
      publicationFailuresBeforeSuccess: 1,
    );
    addTearDown(harness.container.dispose);

    final result = await harness.controller.restore(validMnemonic);

    expect(result.outcome, RestoreWalletOutcome.syncPending);
    expect(harness.wallet!.getBalanceCalls, 1);
    expect(harness.backupStore.confirmedContexts, [aliceContext]);
  });

  test('wallet rebuild failure does not report success', () async {
    final harness = await restoreHarness(walletUnavailable: true);
    addTearDown(harness.container.dispose);

    await expectLater(
      harness.controller.restore(validMnemonic),
      throwsA(
        isA<RestoreWalletFailure>().having(
          (failure) => failure.code,
          'code',
          'wallet_unavailable',
        ),
      ),
    );
    expect(harness.backupStore.confirmedContexts, isEmpty);
  });

  test('context change during restore blocks success and confirmation',
      () async {
    final harness = await restoreHarness(changeContextDuringRestore: true);
    addTearDown(harness.container.dispose);

    await expectLater(
      harness.controller.restore(validMnemonic),
      throwsA(
        isA<RestoreWalletFailure>().having(
          (failure) => failure.code,
          'code',
          'session_changed',
        ),
      ),
    );
    expect(harness.backupStore.confirmedContexts, isEmpty);
  });

  test('authentication denial leaves the active identity untouched', () async {
    final harness = await restoreHarness(authResult: false);
    addTearDown(harness.container.dispose);

    await expectLater(
      harness.controller.restore(validMnemonic),
      throwsA(
        isA<RestoreWalletFailure>().having(
          (failure) => failure.code,
          'code',
          'authentication_denied',
        ),
      ),
    );
    expect(harness.crypto.restoreCalls, 0);
  });

  test('retry rereads identity and clears a transient sync failure', () async {
    final harness = await restoreHarness(
      publicationFailuresBeforeSuccess: 1,
    );
    addTearDown(harness.container.dispose);

    final result = await harness.controller.restore(validMnemonic);
    expect(result.outcome, RestoreWalletOutcome.syncPending);

    expect(await harness.controller.retryPublicKeySync(), isTrue);
    expect(harness.crypto.requireIdentityCalls, 1);
    expect(harness.crypto.publicationCalls, 2);
  });
}
