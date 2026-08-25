import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  Future<void> writeSecret(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions:
          const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  Future<String?> readSecret(String key) async {
    return await _storage.read(
      key: key,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions:
          const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  Future<void> deleteSecret(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> saveWalletSeed(String seedHex) async {
    await writeSecret(AppConstants.keyWalletSeed, seedHex);
  }

  Future<String?> getWalletSeed() async {
    return await readSecret(AppConstants.keyWalletSeed);
  }

  Future<void> clearAllSecrets() async {
    await _storage.deleteAll();
  }
}
