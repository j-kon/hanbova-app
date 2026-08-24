import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/network_environment.dart';
import '../networking/api_client.dart';
import 'secp256k1_service.dart';

class WalletCryptoIdentity {
  final String userId;
  final HanbovaNetwork network;
  final String protectedPaymentPubkey;
  final String transportEncryptionPubkey;
  final SimpleKeyPair transportKeyPair;
  final String protectedPaymentPrivkeyHex;

  const WalletCryptoIdentity({
    required this.userId,
    required this.network,
    required this.protectedPaymentPubkey,
    required this.transportEncryptionPubkey,
    required this.transportKeyPair,
    required this.protectedPaymentPrivkeyHex,
  });
}

final cryptoIdentityProvider =
    AsyncNotifierProvider<CryptoIdentityNotifier, WalletCryptoIdentity?>(() {
  return CryptoIdentityNotifier();
});

class CryptoIdentityNotifier extends AsyncNotifier<WalletCryptoIdentity?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final X25519 _x25519 = X25519();

  @override
  Future<WalletCryptoIdentity?> build() async {
    return null;
  }

  Future<WalletCryptoIdentity> getOrCreateIdentity({
    required String userId,
    required HanbovaNetwork network,
  }) async {
    state = const AsyncValue.loading();
    try {
      final config = NetworkConfig.fromNetwork(network);
      final keyPrefix = 'hanbova_${config.storagePrefix}_$userId';

      final savedTransportPriv = await _storage.read(key: '${keyPrefix}_transport_priv');
      final savedProtectedPriv = await _storage.read(key: '${keyPrefix}_protected_priv');

      SimpleKeyPair transportKeyPair;
      String protectedPaymentPrivHex;

      if (savedTransportPriv != null && savedProtectedPriv != null) {
        // Load existing keys
        final privBytes = base64Decode(savedTransportPriv);
        transportKeyPair = await _x25519.newKeyPairFromSeed(privBytes);
        protectedPaymentPrivHex = savedProtectedPriv;
      } else {
        // Generate new keypairs client-side
        transportKeyPair = await _x25519.newKeyPair();
        final seedBytes = await transportKeyPair.extractPrivateKeyBytes();
        await _storage.write(
          key: '${keyPrefix}_transport_priv',
          value: base64Encode(seedBytes),
        );

        // Generate genuine secp256k1 protected payment key (cryptographically secure scalar)
        protectedPaymentPrivHex = Secp256k1Service.generatePrivateKeyHex();
        await _storage.write(
          key: '${keyPrefix}_protected_priv',
          value: protectedPaymentPrivHex,
        );
      }

      final transportPublicKey = await transportKeyPair.extractPublicKey();
      final transportPubHex = transportPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // Genuine derived 33-byte compressed secp256k1 public key via PointyCastle
      final protectedPubHex = Secp256k1Service.getCompressedPublicKeyHex(protectedPaymentPrivHex);

      final identity = WalletCryptoIdentity(
        userId: userId,
        network: network,
        protectedPaymentPubkey: protectedPubHex,
        transportEncryptionPubkey: transportPubHex,
        transportKeyPair: transportKeyPair,
        protectedPaymentPrivkeyHex: protectedPaymentPrivHex,
      );

      state = AsyncValue.data(identity);
      return identity;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Publish the client-generated public keys to the Hanbova backend directory.
  Future<void> publishPublicKeys({
    required ApiClient apiClient,
    required WalletCryptoIdentity identity,
  }) async {
    await apiClient.put(
      '/me/payment-keys',
      body: {
        'protected_payment_pubkey': identity.protectedPaymentPubkey,
        'transport_encryption_pubkey': identity.transportEncryptionPubkey,
      },
    );
  }

  /// Explicitly removes wallet keys from the device (destructive).
  Future<void> deleteWalletKeys({
    required String userId,
    required HanbovaNetwork network,
  }) async {
    final config = NetworkConfig.fromNetwork(network);
    final keyPrefix = 'hanbova_${config.storagePrefix}_$userId';
    await _storage.delete(key: '${keyPrefix}_transport_priv');
    await _storage.delete(key: '${keyPrefix}_protected_priv');
    state = const AsyncValue.data(null);
  }
}
