import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/core/crypto/crypto_identity_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';

const aliceContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

const bobContext = WalletContextKey(
  userId: 'bob',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

const pilotContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.mainnet,
  storagePrefix: 'wallet_mainnet_pilot',
);

const lockedMainnetContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.mainnet,
  storagePrefix: 'wallet_mainnet',
);

final activeContextStateProvider =
    StateProvider<WalletContextKey?>((ref) => aliceContext);

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FixedIdentityNotifier extends CryptoIdentityNotifier {
  final WalletCryptoIdentity identity;

  FixedIdentityNotifier(this.identity);

  @override
  Future<WalletCryptoIdentity?> build() async => identity;
}

final class RecordingCashuWalletService implements CashuWalletService {
  bool wasDisposed = false;

  @override
  void dispose() {
    wasDisposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserProfile user(String id) => UserProfile(
      id: id,
      username: id,
      handle: '@$id',
      email: '$id@example.test',
      firstName: id,
      lastName: 'Test',
      displayName: '$id Test',
      emailVerified: true,
      createdAt: DateTime.utc(2026),
    );

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
    mnemonic:
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
    walletSeedHex:
        '0000000000000000000000000000000000000000000000000000000000000000',
  );
}

ProviderContainer walletContainer({
  required WalletContextKey activeContext,
  required WalletCryptoIdentity identity,
  required NetworkConfig config,
  CashuWalletServiceFactory? factory,
}) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith(
        (ref) => MockAuthNotifier(
          AuthState.authenticated(user(activeContext.userId), 'token'),
        ),
      ),
      activeContextStateProvider.overrideWith((ref) => activeContext),
      activeWalletContextKeyProvider.overrideWith(
        (ref) => ref.watch(activeContextStateProvider),
      ),
      activeNetworkConfigProvider.overrideWithValue(config),
      cryptoIdentityProvider.overrideWith(
        () => FixedIdentityNotifier(identity),
      ),
      if (factory != null)
        cashuWalletServiceFactoryProvider.overrideWithValue(factory),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Cashu provider stays unavailable for another account identity',
      () async {
    final container = walletContainer(
      activeContext: aliceContext,
      identity: await identityFor(bobContext),
      config: NetworkConfig.cashuTest,
    );
    addTearDown(container.dispose);
    await container.read(cryptoIdentityProvider.future);

    expect(container.read(cashuWalletServiceProvider), isNull);
  });

  test('Cashu provider stays unavailable across mainnet storage prefixes',
      () async {
    final container = walletContainer(
      activeContext: pilotContext,
      identity: await identityFor(lockedMainnetContext),
      config: NetworkConfig.mainnetPilot,
    );
    addTearDown(container.dispose);
    await container.read(cryptoIdentityProvider.future);

    expect(container.read(cashuWalletServiceProvider), isNull);
  });

  test('account switch disposes the prior Cashu service immediately', () async {
    final created = <RecordingCashuWalletService>[];
    CashuWalletService factory({
      required WalletContextKey context,
      required WalletCryptoIdentity identity,
      required String mintUrl,
      required CashuWalletStorage storage,
    }) {
      final service = RecordingCashuWalletService();
      created.add(service);
      return service;
    }

    final container = walletContainer(
      activeContext: aliceContext,
      identity: await identityFor(aliceContext),
      config: NetworkConfig.cashuTest,
      factory: factory,
    );
    addTearDown(container.dispose);
    await container.read(cryptoIdentityProvider.future);

    final first = container.read(cashuWalletServiceProvider);
    expect(first, same(created.single));
    expect(first, isA<CashuWalletService>());

    container.read(activeContextStateProvider.notifier).state = bobContext;
    await container.pump();

    expect(created.single.wasDisposed, isTrue);
    expect(container.read(cashuWalletServiceProvider), isNull);
  });
}
