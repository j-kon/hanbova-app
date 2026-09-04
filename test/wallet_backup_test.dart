import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/wallet_identity_store.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/security/biometric_service.dart';
import 'package:hanbova_app/core/security/wallet_backup_store.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/l10n/app_localizations.dart';
import 'package:hanbova_app/features/security/presentation/backup_seed_screen.dart';

const validMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

const aliceTestContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

const alicePilotContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.mainnet,
  storagePrefix: 'wallet_mainnet_pilot',
);

final class RecordingIdentityStore implements WalletIdentityStore {
  final Map<WalletContextKey, StoredMnemonic> values;
  final Map<WalletContextKey, String> writes = {};

  RecordingIdentityStore({Map<WalletContextKey, StoredMnemonic>? values})
      : values = Map.of(values ?? const {});

  @override
  Future<StoredMnemonic?> read(WalletContextKey context) async =>
      values[context];

  @override
  Future<void> write(WalletContextKey context, String mnemonic) async {
    writes[context] = mnemonic;
    values[context] = StoredMnemonic(
      mnemonic,
      StoredMnemonicSource.canonical,
    );
  }

  @override
  Future<void> delete(WalletContextKey context) async {
    values.remove(context);
  }
}

final class FixedLocalAuthGateway implements LocalAuthGateway {
  final bool result;

  const FixedLocalAuthGateway(this.result);

  @override
  Future<bool> canCheckBiometrics() async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate(String reason) async => result;
}

Widget backupApp({
  required WalletContextKey? activeContext,
  required RecordingIdentityStore identityStore,
  bool authResult = true,
}) {
  return ProviderScope(
    overrides: [
      activeWalletContextKeyProvider.overrideWithValue(activeContext),
      walletIdentityStoreProvider.overrideWithValue(identityStore),
      biometricServiceProvider.overrideWithValue(
        BiometricService(gateway: FixedLocalAuthGateway(authResult)),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BackupSeedScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('confirmation persists and is isolated by complete context', () async {
    final store = SecureWalletBackupStore(
      storage: const FlutterSecureStorage(),
    );

    await store.setConfirmed(aliceTestContext, true);
    expect(await store.isConfirmed(aliceTestContext), isTrue);
    expect(await store.isConfirmed(alicePilotContext), isFalse);

    final reloaded = SecureWalletBackupStore(
      storage: const FlutterSecureStorage(),
    );
    expect(await reloaded.isConfirmed(aliceTestContext), isTrue);
  });

  test('missing and malformed confirmation fail to false', () async {
    FlutterSecureStorage.setMockInitialValues({
      'hanbova_backup_v1_${aliceTestContext.storageId}': 'not-a-bool',
    });
    final store = SecureWalletBackupStore(
      storage: const FlutterSecureStorage(),
    );

    expect(await store.isConfirmed(aliceTestContext), isFalse);
    expect(await store.isConfirmed(alicePilotContext), isFalse);
  });

  testWidgets('Backup never generates a phrase while wallet is unavailable',
      (tester) async {
    final identityStore = RecordingIdentityStore();
    await tester.pumpWidget(
      backupApp(activeContext: null, identityStore: identityStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wallet unavailable'), findsOneWidget);
    expect(find.text('Tap to Reveal 12 Words'), findsNothing);
    expect(identityStore.writes, isEmpty);
  });

  testWidgets('failed device authentication keeps recovery words hidden',
      (tester) async {
    final identityStore = RecordingIdentityStore(values: {
      aliceTestContext: const StoredMnemonic(
        validMnemonic,
        StoredMnemonicSource.canonical,
      ),
    });
    await tester.pumpWidget(
      backupApp(
        activeContext: aliceTestContext,
        identityStore: identityStore,
        authResult: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to Reveal 12 Words'));
    await tester.pump();

    expect(find.text('••••••••'), findsWidgets);
    expect(find.text('Authentication was not completed.'), findsOneWidget);
    expect(find.text('abandon'), findsNothing);
    expect(identityStore.writes, isEmpty);
  });
}
