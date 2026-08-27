import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/digests/sha256.dart';
import '../network/network_environment.dart';
import '../networking/api_client.dart';
import 'mnemonic_service.dart';
import 'secp256k1_service.dart';

class WalletCryptoIdentity {
  final String userId;
  final HanbovaNetwork network;
  final String walletEnvironment;
  final String protectedPaymentPubkey;
  final String transportEncryptionPubkey;
  final SimpleKeyPair transportKeyPair;
  final String protectedPaymentPrivkeyHex;
  final String mnemonic;
  final String walletSeedHex;

  const WalletCryptoIdentity({
    required this.userId,
    required this.network,
    required this.walletEnvironment,
    required this.protectedPaymentPubkey,
    required this.transportEncryptionPubkey,
    required this.transportKeyPair,
    required this.protectedPaymentPrivkeyHex,
    required this.mnemonic,
    required this.walletSeedHex,
  });

  String get transportKeyFingerprint =>
      CryptoIdentityNotifier.computeFingerprint(transportEncryptionPubkey);
  String get protectedPaymentFingerprint =>
      CryptoIdentityNotifier.computeFingerprint(protectedPaymentPubkey);
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

  /// Calculates a non-secret, 16-character SHA-256 hex fingerprint of a public key.
  static String computeFingerprint(String pubkeyHex) {
    final clean = pubkeyHex.trim().toLowerCase();
    final bytes = Secp256k1Service.hexToBytes(clean);
    final digest = SHA256Digest().process(bytes);
    return Secp256k1Service.bytesToHex(digest).substring(0, 16);
  }

  /// Derives the 32-byte private key hex scalar for P2PK (secp256k1) deterministically from seed.
  static Future<String> deriveProtectedPaymentPrivHex(String seedHex) async {
    final seedBytes = Secp256k1Service.hexToBytes(seedHex);
    final hmac = Hmac(Sha512());
    final mac = await hmac.calculateMac(
      seedBytes,
      secretKey: SecretKey(utf8.encode('Hanbova P2PK Identity Derivation')),
    );
    final keyBytes = mac.bytes.sublist(0, 32);
    // Verify scalar is valid, if not derive next 32 bytes
    if (!Secp256k1Service.isValidPrivateKey(Uint8List.fromList(keyBytes))) {
      final keyBytesAlt = mac.bytes.sublist(32, 64);
      return Secp256k1Service.bytesToHex(keyBytesAlt);
    }
    return Secp256k1Service.bytesToHex(keyBytes);
  }

  /// Derives the X25519 transport keypair deterministically from seed.
  static Future<SimpleKeyPair> deriveTransportKeyPair(
      String seedHex, X25519 x25519) async {
    final seedBytes = Secp256k1Service.hexToBytes(seedHex);
    final hmac = Hmac(Sha512());
    final mac = await hmac.calculateMac(
      seedBytes,
      secretKey: SecretKey(utf8.encode('Hanbova X25519 Transport Derivation')),
    );
    final keyBytes = mac.bytes.sublist(0, 32);
    return x25519.newKeyPairFromSeed(keyBytes);
  }

  Future<WalletCryptoIdentity> getOrCreateIdentity({
    required String userId,
    required HanbovaNetwork network,
    NetworkConfig? config,
  }) async {
    state = const AsyncValue.loading();
    try {
      final effectiveConfig = config ?? NetworkConfig.fromNetwork(network);
      final envName = effectiveConfig.storagePrefix;
      final keyPrefix = 'hanbova_${envName}_$userId';

      String? savedMnemonic = await _storage.read(key: '${keyPrefix}_mnemonic');

      if (savedMnemonic == null || savedMnemonic.trim().isEmpty) {
        savedMnemonic = await MnemonicService.generateMnemonic();
        await _storage.write(
          key: '${keyPrefix}_mnemonic',
          value: savedMnemonic,
        );
      }

      final walletSeedHex =
          await MnemonicService.mnemonicToSeedHex(savedMnemonic);

      // Derive deterministically from the user's BIP-39 mnemonic seed
      final transportKeyPair =
          await deriveTransportKeyPair(walletSeedHex, _x25519);
      final protectedPaymentPrivHex =
          await deriveProtectedPaymentPrivHex(walletSeedHex);

      final transportPublicKey = await transportKeyPair.extractPublicKey();
      final transportPubHex = transportPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // Derived 33-byte compressed secp256k1 public key via PointyCastle
      final protectedPubHex =
          Secp256k1Service.getCompressedPublicKeyHex(protectedPaymentPrivHex);

      final identity = WalletCryptoIdentity(
        userId: userId,
        network: network,
        walletEnvironment: envName,
        protectedPaymentPubkey: protectedPubHex,
        transportEncryptionPubkey: transportPubHex,
        transportKeyPair: transportKeyPair,
        protectedPaymentPrivkeyHex: protectedPaymentPrivHex,
        mnemonic: savedMnemonic,
        walletSeedHex: walletSeedHex,
      );

      state = AsyncValue.data(identity);
      return identity;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Restores identity deterministically from a 12-word BIP-39 mnemonic.
  Future<WalletCryptoIdentity> restoreFromMnemonic({
    required String mnemonic,
    required String userId,
    required HanbovaNetwork network,
    NetworkConfig? config,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isValid = await MnemonicService.validateMnemonic(mnemonic);
      if (!isValid) {
        throw ArgumentError('Invalid 12-word BIP-39 mnemonic phrase');
      }

      final effectiveConfig = config ?? NetworkConfig.fromNetwork(network);
      final envName = effectiveConfig.storagePrefix;
      final keyPrefix = 'hanbova_${envName}_$userId';
      final cleanMnemonic = mnemonic.trim().toLowerCase();

      final walletSeedHex =
          await MnemonicService.mnemonicToSeedHex(cleanMnemonic);
      final transportKeyPair =
          await deriveTransportKeyPair(walletSeedHex, _x25519);
      final protectedPaymentPrivHex =
          await deriveProtectedPaymentPrivHex(walletSeedHex);

      await _storage.write(
        key: '${keyPrefix}_mnemonic',
        value: cleanMnemonic,
      );

      final transportPublicKey = await transportKeyPair.extractPublicKey();
      final transportPubHex = transportPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final protectedPubHex =
          Secp256k1Service.getCompressedPublicKeyHex(protectedPaymentPrivHex);

      final identity = WalletCryptoIdentity(
        userId: userId,
        network: network,
        walletEnvironment: envName,
        protectedPaymentPubkey: protectedPubHex,
        transportEncryptionPubkey: transportPubHex,
        transportKeyPair: transportKeyPair,
        protectedPaymentPrivkeyHex: protectedPaymentPrivHex,
        mnemonic: cleanMnemonic,
        walletSeedHex: walletSeedHex,
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
    String? walletEnvironment,
  }) async {
    final env = walletEnvironment ?? identity.walletEnvironment;
    await apiClient.put(
      '/me/payment-keys',
      body: {
        'protected_payment_pubkey': identity.protectedPaymentPubkey,
        'transport_encryption_pubkey': identity.transportEncryptionPubkey,
        'wallet_environment': env,
      },
    );
  }

  /// Explicitly removes wallet keys from the device (destructive).
  Future<void> deleteWalletKeys({
    required String userId,
    required HanbovaNetwork network,
    NetworkConfig? config,
  }) async {
    final effectiveConfig = config ?? NetworkConfig.fromNetwork(network);
    final envName = effectiveConfig.storagePrefix;
    final keyPrefix = 'hanbova_${envName}_$userId';
    await _storage.delete(key: '${keyPrefix}_transport_priv');
    await _storage.delete(key: '${keyPrefix}_protected_priv');
    await _storage.delete(key: '${keyPrefix}_mnemonic');
    state = const AsyncValue.data(null);
  }
}
