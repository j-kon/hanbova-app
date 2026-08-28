import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../wallet/wallet_context.dart';

enum StoredMnemonicSource { canonical, legacy }

final class StoredMnemonic {
  final String mnemonic;
  final StoredMnemonicSource source;

  const StoredMnemonic(this.mnemonic, this.source);
}

abstract interface class WalletIdentityStore {
  Future<StoredMnemonic?> read(WalletContextKey context);

  Future<void> write(WalletContextKey context, String mnemonic);

  Future<void> delete(WalletContextKey context);
}

final class SecureWalletIdentityStore implements WalletIdentityStore {
  final FlutterSecureStorage storage;

  const SecureWalletIdentityStore({required this.storage});

  @override
  Future<StoredMnemonic?> read(WalletContextKey context) async {
    final canonical = await storage.read(
      key: '${context.identityStoragePrefix}_mnemonic',
    );
    if (canonical != null && canonical.trim().isNotEmpty) {
      return StoredMnemonic(canonical, StoredMnemonicSource.canonical);
    }

    final legacy = await storage.read(
      key: '${context.legacyIdentityStoragePrefix}_mnemonic',
    );
    if (legacy == null || legacy.trim().isEmpty) {
      return null;
    }
    return StoredMnemonic(legacy, StoredMnemonicSource.legacy);
  }

  @override
  Future<void> write(WalletContextKey context, String mnemonic) {
    return storage.write(
      key: '${context.identityStoragePrefix}_mnemonic',
      value: mnemonic,
    );
  }

  @override
  Future<void> delete(WalletContextKey context) async {
    for (final prefix in <String>{
      context.identityStoragePrefix,
      context.legacyIdentityStoragePrefix,
    }) {
      await storage.delete(key: '${prefix}_mnemonic');
      await storage.delete(key: '${prefix}_transport_priv');
      await storage.delete(key: '${prefix}_protected_priv');
    }
  }
}

final walletIdentityStoreProvider = Provider<WalletIdentityStore>((ref) {
  return const SecureWalletIdentityStore(storage: FlutterSecureStorage());
});
