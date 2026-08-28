import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/wallet_identity_store.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';

const validMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

const testContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

const pilotContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.mainnet,
  storagePrefix: 'wallet_mainnet_pilot',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('canonical mnemonic is isolated by complete wallet context', () async {
    const storage = FlutterSecureStorage();
    const store = SecureWalletIdentityStore(storage: storage);

    await store.write(testContext, validMnemonic);

    final loaded = await store.read(testContext);
    expect(loaded?.mnemonic, validMnemonic);
    expect(loaded?.source, StoredMnemonicSource.canonical);
    expect(await store.read(pilotContext), isNull);
  });

  test('read returns a compatible legacy mnemonic without deleting it',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      '${testContext.legacyIdentityStoragePrefix}_mnemonic': validMnemonic,
    });
    const storage = FlutterSecureStorage();
    const store = SecureWalletIdentityStore(storage: storage);

    final loaded = await store.read(testContext);

    expect(loaded?.source, StoredMnemonicSource.legacy);
    expect(loaded?.mnemonic, validMnemonic);
    expect(
      await storage.read(
        key: '${testContext.legacyIdentityStoragePrefix}_mnemonic',
      ),
      validMnemonic,
    );
    expect(
      await storage.read(key: '${testContext.identityStoragePrefix}_mnemonic'),
      isNull,
    );
  });

  test('canonical mnemonic takes precedence over a legacy value', () async {
    const canonicalMnemonic = validMnemonic;
    const legacyMnemonic =
        'legal winner thank year wave sausage worth useful legal winner thank yellow';
    FlutterSecureStorage.setMockInitialValues({
      '${testContext.identityStoragePrefix}_mnemonic': canonicalMnemonic,
      '${testContext.legacyIdentityStoragePrefix}_mnemonic': legacyMnemonic,
    });
    const store = SecureWalletIdentityStore(
      storage: FlutterSecureStorage(),
    );

    final loaded = await store.read(testContext);

    expect(loaded?.mnemonic, canonicalMnemonic);
    expect(loaded?.source, StoredMnemonicSource.canonical);
  });

  test('delete removes only the requested context identity keys', () async {
    const storage = FlutterSecureStorage();
    const store = SecureWalletIdentityStore(storage: storage);
    await store.write(testContext, validMnemonic);
    await store.write(pilotContext, validMnemonic);
    await storage.write(
      key: '${testContext.legacyIdentityStoragePrefix}_transport_priv',
      value: 'legacy-transport',
    );
    await storage.write(
      key: '${testContext.legacyIdentityStoragePrefix}_protected_priv',
      value: 'legacy-protected',
    );

    await store.delete(testContext);

    expect(await store.read(testContext), isNull);
    expect(await store.read(pilotContext), isNotNull);
    expect(
      await storage.read(
        key: '${testContext.legacyIdentityStoragePrefix}_transport_priv',
      ),
      isNull,
    );
    expect(
      await storage.read(
        key: '${testContext.legacyIdentityStoragePrefix}_protected_priv',
      ),
      isNull,
    );
  });

  test('empty stored values are treated as missing', () async {
    FlutterSecureStorage.setMockInitialValues({
      '${testContext.identityStoragePrefix}_mnemonic': '   ',
      '${testContext.legacyIdentityStoragePrefix}_mnemonic': '',
    });
    const store = SecureWalletIdentityStore(
      storage: FlutterSecureStorage(),
    );

    expect(await store.read(testContext), isNull);
  });
}
