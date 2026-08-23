import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class ProtectedPaymentEnvelope {
  final int version;
  final String type;
  final String paymentId;
  final String cashuToken;
  final String mintUrl;
  final int amountSats;
  final String senderUsername;
  final String recipientUsername;
  final int locktime;

  const ProtectedPaymentEnvelope({
    this.version = 1,
    this.type = 'hanbova_protected_payment',
    required this.paymentId,
    required this.cashuToken,
    required this.mintUrl,
    required this.amountSats,
    required this.senderUsername,
    required this.recipientUsername,
    required this.locktime,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'type': type,
        'payment_id': paymentId,
        'cashu_token': cashuToken,
        'mint_url': mintUrl,
        'amount_sats': amountSats,
        'sender_username': senderUsername,
        'recipient_username': recipientUsername,
        'locktime': locktime,
      };

  factory ProtectedPaymentEnvelope.fromJson(Map<String, dynamic> json) {
    final ver = json['version'] as int? ?? 1;
    if (ver != 1) {
      throw FormatException('Unsupported envelope version: $ver');
    }
    return ProtectedPaymentEnvelope(
      version: ver,
      type: json['type'] as String? ?? 'hanbova_protected_payment',
      paymentId: json['payment_id'] as String,
      cashuToken: json['cashu_token'] as String,
      mintUrl: json['mint_url'] as String,
      amountSats: json['amount_sats'] as int,
      senderUsername: json['sender_username'] as String,
      recipientUsername: json['recipient_username'] as String,
      locktime: json['locktime'] as int,
    );
  }
}

class EncryptedEnvelopeService {
  final X25519 _x25519 = X25519();
  final Cipher _cipher = Chacha20.poly1305Aead();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Encrypt a protected payment envelope for a recipient's transport public key.
  Future<String> encryptEnvelope({
    required ProtectedPaymentEnvelope envelope,
    required String recipientTransportPubkeyHex,
  }) async {
    final recipientPubBytes = _hexToBytes(recipientTransportPubkeyHex);
    final recipientPublicKey = SimplePublicKey(
      recipientPubBytes,
      type: KeyPairType.x25519,
    );

    // 1. Generate ephemeral keypair for forward secrecy
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // 2. Perform ECDH to get shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // 3. Derive symmetric encryption key via HKDF
    final derivedSecretKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode('hanbova_transport_v1'),
    );

    // 4. Encrypt JSON payload with ChaCha20-Poly1305 AEAD
    final plaintext = utf8.encode(jsonEncode(envelope.toJson()));
    final secretBox = await _cipher.encrypt(
      plaintext,
      secretKey: derivedSecretKey,
    );

    final ephemHex = _bytesToHex(ephemeralPublicKey.bytes);
    final nonceHex = _bytesToHex(secretBox.nonce);
    final cipherHex = _bytesToHex(secretBox.cipherText);
    final macHex = _bytesToHex(secretBox.mac.bytes);

    return 'v1:$ephemHex:$nonceHex:$cipherHex:$macHex';
  }

  /// Decrypt a protected payment envelope using the recipient's transport keypair.
  Future<ProtectedPaymentEnvelope> decryptEnvelope({
    required String ciphertextString,
    required SimpleKeyPair recipientKeyPair,
  }) async {
    final parts = ciphertextString.split(':');
    if (parts.length != 5 || parts[0] != 'v1') {
      throw const FormatException('Invalid ciphertext format');
    }

    final ephemPubBytes = _hexToBytes(parts[1]);
    final nonceBytes = _hexToBytes(parts[2]);
    final cipherBytes = _hexToBytes(parts[3]);
    final macBytes = _hexToBytes(parts[4]);

    final ephemeralPublicKey = SimplePublicKey(
      ephemPubBytes,
      type: KeyPairType.x25519,
    );

    // 1. Perform ECDH to get shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: ephemeralPublicKey,
    );

    // 2. Derive symmetric key via HKDF
    final derivedSecretKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode('hanbova_transport_v1'),
    );

    // 3. Decrypt with ChaCha20-Poly1305 AEAD
    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final decryptedBytes = await _cipher.decrypt(
      secretBox,
      secretKey: derivedSecretKey,
    );

    final jsonMap = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
    return ProtectedPaymentEnvelope.fromJson(jsonMap);
  }

  Uint8List _hexToBytes(String hex) {
    final clean = hex.replaceAll(' ', '');
    final result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      result[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
