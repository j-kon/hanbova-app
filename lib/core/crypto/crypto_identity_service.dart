import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointycastle/digests/sha256.dart';
import '../network/network_environment.dart';
import '../networking/api_client.dart';
import '../wallet/wallet_context.dart';
import 'mnemonic_service.dart';
import 'secp256k1_service.dart';
import 'wallet_identity_store.dart';

final class WalletContextUnavailableException implements Exception {
  const WalletContextUnavailableException();

  @override
  String toString() => 'An authenticated wallet context is required.';
}

final class WalletIdentityUnavailableException implements Exception {
  const WalletIdentityUnavailableException();

  @override
  String toString() => 'No wallet identity exists for the active context.';
}

final class StaleWalletContextException implements Exception {
  const StaleWalletContextException();

  @override
  String toString() => 'The active wallet context changed.';
}

class WalletCryptoIdentity {
  final WalletContextKey context;
  final String protectedPaymentPubkey;
  final String transportEncryptionPubkey;
  final SimpleKeyPair transportKeyPair;
  final String protectedPaymentPrivkeyHex;
  final String mnemonic;
  final String walletSeedHex;

  const WalletCryptoIdentity({
    required this.context,
    required this.protectedPaymentPubkey,
    required this.transportEncryptionPubkey,
    required this.transportKeyPair,
    required this.protectedPaymentPrivkeyHex,
    required this.mnemonic,
    required this.walletSeedHex,
  });

  String get userId => context.userId;
  HanbovaNetwork get network => context.network;
  String get walletEnvironment => context.storagePrefix;

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
  final X25519 _x25519 = X25519();
  WalletContextKey? _activeContext;

  @override
  Future<WalletCryptoIdentity?> build() async {
    _activeContext = ref.read(activeWalletContextKeyProvider);
    ref.listen<WalletContextKey?>(
      activeWalletContextKeyProvider,
      (previous, next) {
        _activeContext = next;
        if (previous != next) {
          state = const AsyncValue.data(null);
        }
      },
    );
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

  WalletContextKey _captureContext() {
    final context = _activeContext;
    if (context == null) {
      throw const WalletContextUnavailableException();
    }
    return context;
  }

  void _ensureCurrent(WalletContextKey captured) {
    if (_activeContext != captured) {
      throw const StaleWalletContextException();
    }
  }

  void _publishIfCurrent(
    WalletContextKey captured,
    WalletCryptoIdentity identity,
  ) {
    _ensureCurrent(captured);
    state = AsyncValue.data(identity);
  }

  void _setErrorIfCurrent(
    WalletContextKey captured,
    Object error,
    StackTrace stackTrace,
  ) {
    if (_activeContext == captured) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<WalletCryptoIdentity> _deriveIdentity(
    WalletContextKey context,
    String mnemonic,
  ) async {
    final cleanMnemonic = mnemonic.trim().toLowerCase();
    if (!await MnemonicService.validateMnemonic(cleanMnemonic)) {
      throw ArgumentError('Invalid 12-word BIP-39 mnemonic phrase');
    }

    final walletSeedHex =
        await MnemonicService.mnemonicToSeedHex(cleanMnemonic);
    final transportKeyPair =
        await deriveTransportKeyPair(walletSeedHex, _x25519);
    final protectedPaymentPrivHex =
        await deriveProtectedPaymentPrivHex(walletSeedHex);
    final transportPublicKey = await transportKeyPair.extractPublicKey();
    final transportPubHex = transportPublicKey.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final protectedPubHex =
        Secp256k1Service.getCompressedPublicKeyHex(protectedPaymentPrivHex);

    return WalletCryptoIdentity(
      context: context,
      protectedPaymentPubkey: protectedPubHex,
      transportEncryptionPubkey: transportPubHex,
      transportKeyPair: transportKeyPair,
      protectedPaymentPrivkeyHex: protectedPaymentPrivHex,
      mnemonic: cleanMnemonic,
      walletSeedHex: walletSeedHex,
    );
  }

  Future<WalletCryptoIdentity> _loadStoredIdentity(
    WalletContextKey context,
    StoredMnemonic stored,
  ) async {
    final identity = await _deriveIdentity(context, stored.mnemonic);
    _ensureCurrent(context);
    if (stored.source == StoredMnemonicSource.legacy) {
      await ref
          .read(walletIdentityStoreProvider)
          .write(context, identity.mnemonic);
      _ensureCurrent(context);
    }
    return identity;
  }

  Future<WalletCryptoIdentity> requireIdentity() async {
    final context = _captureContext();
    final loaded = state.valueOrNull;
    if (loaded?.context == context) {
      return loaded!;
    }

    state = const AsyncValue.loading();
    try {
      final stored = await ref.read(walletIdentityStoreProvider).read(context);
      if (stored == null) {
        throw const WalletIdentityUnavailableException();
      }
      final identity = await _loadStoredIdentity(context, stored);
      _publishIfCurrent(context, identity);
      return identity;
    } catch (error, stackTrace) {
      _setErrorIfCurrent(context, error, stackTrace);
      rethrow;
    }
  }

  Future<WalletCryptoIdentity> getOrCreateIdentity() async {
    final context = _captureContext();
    final loaded = state.valueOrNull;
    if (loaded?.context == context) {
      return loaded!;
    }

    state = const AsyncValue.loading();
    try {
      final store = ref.read(walletIdentityStoreProvider);
      final stored = await store.read(context);
      if (stored != null) {
        final identity = await _loadStoredIdentity(context, stored);
        _publishIfCurrent(context, identity);
        return identity;
      }

      final mnemonic = await MnemonicService.generateMnemonic();
      final identity = await _deriveIdentity(context, mnemonic);
      _ensureCurrent(context);
      await store.write(context, identity.mnemonic);
      _publishIfCurrent(context, identity);
      return identity;
    } catch (error, stackTrace) {
      _setErrorIfCurrent(context, error, stackTrace);
      rethrow;
    }
  }

  /// Restores identity deterministically from a 12-word BIP-39 mnemonic.
  Future<WalletCryptoIdentity> restoreFromMnemonic({
    required String mnemonic,
  }) async {
    final context = _captureContext();
    state = const AsyncValue.loading();
    try {
      final identity = await _deriveIdentity(context, mnemonic);
      _ensureCurrent(context);
      await ref
          .read(walletIdentityStoreProvider)
          .write(context, identity.mnemonic);
      _publishIfCurrent(context, identity);
      return identity;
    } catch (error, stackTrace) {
      _setErrorIfCurrent(context, error, stackTrace);
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
  Future<void> deleteWalletKeys() async {
    final context = _captureContext();
    await ref.read(walletIdentityStoreProvider).delete(context);
    if (_activeContext == context) {
      state = const AsyncValue.data(null);
    }
  }
}
