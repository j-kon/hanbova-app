import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Cryptographic service providing genuine secp256k1 elliptic curve operations
/// using PointyCastle's audited implementation for Cashu NUT-11 P2PK keys.
class Secp256k1Service {
  static final ECDomainParameters _domain = ECDomainParameters('secp256k1');

  /// The order of the secp256k1 curve base point.
  static BigInt get curveOrder => _domain.n;

  /// Generates a cryptographically secure 32-byte private key scalar.
  /// Guarantees that the scalar d is within the valid range [1, n - 1].
  static Uint8List generatePrivateKey() {
    final random = Random.secure();
    final bytes = Uint8List(32);
    while (true) {
      for (int i = 0; i < 32; i++) {
        bytes[i] = random.nextInt(256);
      }
      final scalar = _decodeBigInt(bytes);
      if (scalar > BigInt.zero && scalar < _domain.n) {
        return bytes;
      }
    }
  }

  /// Generates a valid private key returned as a 64-character lowercase hex string.
  static String generatePrivateKeyHex() {
    return bytesToHex(generatePrivateKey());
  }

  /// Derives the 33-byte compressed secp256k1 public key from a 32-byte private key.
  /// Computes Q = G * d and serializes in compressed format (prefix 0x02 or 0x03).
  static Uint8List getCompressedPublicKey(Uint8List privateKey) {
    if (privateKey.length != 32) {
      throw ArgumentError('Private key must be exactly 32 bytes');
    }
    final scalar = _decodeBigInt(privateKey);
    if (scalar <= BigInt.zero || scalar >= _domain.n) {
      throw ArgumentError('Private key scalar must be in range [1, n - 1]');
    }

    final point = _domain.G * scalar;
    if (point == null || point.isInfinity) {
      throw ArgumentError('Derived public key point cannot be at infinity');
    }

    // getEncoded(true) returns 33-byte compressed representation
    return Uint8List.fromList(point.getEncoded(true));
  }

  /// Derives the compressed public key from a hex-encoded private key,
  /// returning a 66-character lowercase hex string (starting with '02' or '03').
  static String getCompressedPublicKeyHex(String privateKeyHex) {
    final cleanHex = privateKeyHex.trim().toLowerCase();
    final privBytes = hexToBytes(cleanHex);
    final pubBytes = getCompressedPublicKey(privBytes);
    return bytesToHex(pubBytes);
  }

  /// Validates whether a given private key scalar is within [1, n - 1].
  static bool isValidPrivateKey(Uint8List privateKey) {
    if (privateKey.length != 32) return false;
    final scalar = _decodeBigInt(privateKey);
    return scalar > BigInt.zero && scalar < _domain.n;
  }

  /// Validates whether a hex string is a valid 33-byte compressed secp256k1 public key.
  static bool isValidCompressedPublicKeyHex(String pubkeyHex) {
    final clean = pubkeyHex.trim().toLowerCase();
    if (clean.length != 66) return false;
    if (!clean.startsWith('02') && !clean.startsWith('03')) return false;

    try {
      final bytes = hexToBytes(clean);
      final point = _domain.curve.decodePoint(bytes);
      return point != null && !point.isInfinity;
    } catch (_) {
      return false;
    }
  }

  /// Helper: converts byte array to hex string.
  static String bytesToHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Helper: converts hex string to Uint8List.
  static Uint8List hexToBytes(String hex) {
    final clean = hex.trim();
    if (clean.length % 2 != 0) {
      throw ArgumentError('Hex string must have an even length');
    }
    final result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      result[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static BigInt _decodeBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
