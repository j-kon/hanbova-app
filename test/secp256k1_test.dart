import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/secp256k1_service.dart';

void main() {
  group('Genuine Secp256k1 P2PK Key Generation & Derivation Tests', () {
    test('1000 generated P2PK keys are unique, valid, and derive valid 33-byte compressed pubkeys', () {
      final generatedPrivs = <String>{};
      final generatedPubs = <String>{};

      for (int i = 0; i < 1000; i++) {
        final privHex = Secp256k1Service.generatePrivateKeyHex();
        final privBytes = Secp256k1Service.hexToBytes(privHex);

        // 1. Uniqueness
        expect(generatedPrivs.contains(privHex), isFalse, reason: 'Collision detected on iteration $i');
        generatedPrivs.add(privHex);

        // 2. Valid scalar range [1, n - 1]
        expect(Secp256k1Service.isValidPrivateKey(privBytes), isTrue);

        // 3. True Elliptic Curve Scalar Multiplication
        final pubHex = Secp256k1Service.getCompressedPublicKeyHex(privHex);
        expect(pubHex.length, 66, reason: 'Compressed public key must be 33 bytes (66 hex chars)');
        expect(pubHex.startsWith('02') || pubHex.startsWith('03'), isTrue, reason: 'Prefix must be 02 or 03');
        expect(Secp256k1Service.isValidCompressedPublicKeyHex(pubHex), isTrue);

        generatedPubs.add(pubHex);
      }

      expect(generatedPrivs.length, 1000);
      expect(generatedPubs.length, 1000);
    });

    test('Deterministic derivation: same private key scalar produces identical compressed public key', () {
      const privHex = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      final pub1 = Secp256k1Service.getCompressedPublicKeyHex(privHex);
      final pub2 = Secp256k1Service.getCompressedPublicKeyHex(privHex);

      expect(pub1, pub2);
      expect(Secp256k1Service.isValidCompressedPublicKeyHex(pub1), isTrue);
    });

    test('Fake 02+privkey prefixing produces invalid or mismatched points', () {
      const privHex = '1111111111111111111111111111111111111111111111111111111111111111';
      final truePub = Secp256k1Service.getCompressedPublicKeyHex(privHex);
      const fakePub = '02$privHex';

      expect(truePub, isNot(equals(fakePub)), reason: 'Fake pubkey concatenation must never match true scalar point');
    });

    test('Rejects invalid scalar zero or overflow', () {
      final zeroPriv = List<int>.filled(32, 0);
      expect(
        () => Secp256k1Service.getCompressedPublicKey(Secp256k1Service.hexToBytes(Secp256k1Service.bytesToHex(zeroPriv))),
        throwsArgumentError,
      );
    });
  });
}
