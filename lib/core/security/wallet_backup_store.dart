import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/crypto_identity_service.dart';
import '../wallet/wallet_context.dart';

abstract interface class WalletBackupStore {
  Future<bool> isConfirmed(WalletContextKey context);

  Future<void> setConfirmed(WalletContextKey context, bool value);
}

final class SecureWalletBackupStore implements WalletBackupStore {
  final FlutterSecureStorage storage;

  const SecureWalletBackupStore({required this.storage});

  String _key(WalletContextKey context) =>
      'hanbova_backup_v1_${context.storageId}';

  @override
  Future<bool> isConfirmed(WalletContextKey context) async =>
      await storage.read(key: _key(context)) == 'true';

  @override
  Future<void> setConfirmed(WalletContextKey context, bool value) =>
      storage.write(key: _key(context), value: value.toString());
}

final walletBackupStoreProvider = Provider<WalletBackupStore>((ref) {
  return const SecureWalletBackupStore(storage: FlutterSecureStorage());
});

final walletBackupStatusProvider =
    AsyncNotifierProvider<WalletBackupStatusNotifier, bool>(
  WalletBackupStatusNotifier.new,
);

final class WalletBackupStatusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final context = ref.watch(activeWalletContextKeyProvider);
    if (context == null) return false;
    return ref.watch(walletBackupStoreProvider).isConfirmed(context);
  }

  Future<void> confirm() async {
    final context = ref.read(activeWalletContextKeyProvider);
    if (context == null) {
      throw const WalletContextUnavailableException();
    }

    await ref.read(walletBackupStoreProvider).setConfirmed(context, true);
    if (ref.read(activeWalletContextKeyProvider) != context) {
      throw const StaleWalletContextException();
    }
    state = const AsyncValue.data(true);
  }
}
