import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/encrypted_envelope_service.dart';

void main() {
  group('End-to-End Encrypted Envelope & Crypto Tests', () {
    final x25519 = X25519();
    final envelopeService = EncryptedEnvelopeService();

    test('Alice encrypts envelope for Bob, Bob decrypts successfully',
        () async {
      // 1. Generate Bob's Transport KeyPair
      final bobKeyPair = await x25519.newKeyPair();
      final bobPublicKey = await bobKeyPair.extractPublicKey();
      final bobPubHex = bobPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // 2. Alice creates a Protected Payment Envelope
      const envelope = ProtectedPaymentEnvelope(
        version: 1,
        paymentId: 'pay_test_uuid_12345',
        cashuToken:
            'cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vdGVzdG51dC5jYXNodS5zcGFjZSIsInByb29mcyI6W3siaWQiOiIwMCIsImFtb3VudCI6NTAwLCJzZWNyZXQiOiJbMDJudXQxMTowMmJvYnB1YmtleTpsb2NrdGltZT0xNzg3NTEwNDAwOnJlZnVuZD0wMmFsaWNlcHVia2V5XSJdfV1dfQ==',
        mintUrl: 'https://testnut.cashu.space',
        amountSats: 500,
        senderUsername: 'alice',
        recipientUsername: 'bob',
        locktime: 1787510400,
      );

      // 3. Alice encrypts the envelope using Bob's public transport key
      final ciphertext = await envelopeService.encryptEnvelope(
        envelope: envelope,
        recipientTransportPubkeyHex: bobPubHex,
      );

      expect(ciphertext.startsWith('v1:'), isTrue);
      expect(ciphertext.split(':').length, 5);

      // 4. Bob decrypts the envelope using his private transport key
      final decrypted = await envelopeService.decryptEnvelope(
        ciphertextString: ciphertext,
        recipientKeyPair: bobKeyPair,
      );

      expect(decrypted.version, 1);
      expect(decrypted.paymentId, 'pay_test_uuid_12345');
      expect(decrypted.amountSats, 500);
      expect(decrypted.senderUsername, 'alice');
      expect(decrypted.recipientUsername, 'bob');
      expect(decrypted.locktime, 1787510400);
      expect(decrypted.cashuToken, envelope.cashuToken);
      expect(decrypted.mintUrl, 'https://testnut.cashu.space');
    });

    test('Charlie cannot decrypt an envelope encrypted for Bob', () async {
      final bobKeyPair = await x25519.newKeyPair();
      final bobPublicKey = await bobKeyPair.extractPublicKey();
      final bobPubHex = bobPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      final charlieKeyPair = await x25519.newKeyPair();

      const envelope = ProtectedPaymentEnvelope(
        version: 1,
        paymentId: 'pay_secret_999',
        cashuToken: 'cashuA_secret_ecash_token',
        mintUrl: 'http://127.0.0.1:3338',
        amountSats: 1000,
        senderUsername: 'alice',
        recipientUsername: 'bob',
        locktime: 1787510400,
      );

      final ciphertext = await envelopeService.encryptEnvelope(
        envelope: envelope,
        recipientTransportPubkeyHex: bobPubHex,
      );

      // Charlie tries to decrypt Bob's message -> Must fail with SecretBoxAuthenticationError / Decryption error
      expect(
        () async => await envelopeService.decryptEnvelope(
          ciphertextString: ciphertext,
          recipientKeyPair: charlieKeyPair,
        ),
        throwsA(anything),
      );
    });

    test('Tampered ciphertext fails authentication', () async {
      final bobKeyPair = await x25519.newKeyPair();
      final bobPublicKey = await bobKeyPair.extractPublicKey();
      final bobPubHex = bobPublicKey.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      const envelope = ProtectedPaymentEnvelope(
        version: 1,
        paymentId: 'pay_tamper_test',
        cashuToken: 'cashuA_test',
        mintUrl: 'http://127.0.0.1:3338',
        amountSats: 250,
        senderUsername: 'alice',
        recipientUsername: 'bob',
        locktime: 1787510400,
      );

      final ciphertext = await envelopeService.encryptEnvelope(
        envelope: envelope,
        recipientTransportPubkeyHex: bobPubHex,
      );

      // Tamper with one character in ciphertext
      final parts = ciphertext.split(':');
      final firstChar = parts[3][0];
      final replacement = firstChar == 'a' ? 'b' : 'a';
      final tamperedCipher = '$replacement${parts[3].substring(1)}';
      final tamperedString =
          '${parts[0]}:${parts[1]}:${parts[2]}:$tamperedCipher:${parts[4]}';

      expect(
        () async => await envelopeService.decryptEnvelope(
          ciphertextString: tamperedString,
          recipientKeyPair: bobKeyPair,
        ),
        throwsA(anything),
      );
    });
  });
}
