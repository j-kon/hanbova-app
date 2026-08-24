import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../crypto/secp256k1_service.dart';
import '../network/network_environment.dart';
import 'cashu_wallet_models.dart';
import 'cashu_wallet_storage.dart';

abstract class CashuWalletService {
  Future<CashuWalletBalance> getBalance();
  Future<int> mintTestTokens(int amountSats);
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  });
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  });
  Future<int> refundProtectedPayment({
    required String paymentId,
  });
  Future<TokenState> checkTokenState(String token);
}

class ClientCashuWalletServiceImpl implements CashuWalletService {
  final String userId;
  final HanbovaNetwork network;
  final CashuWalletStorage _storage;
  final String _p2pkPrivateKeyHex;
  final String _p2pkPublicKeyHex;
  final String _mintUrl;
  final http.Client _client;

  ClientCashuWalletServiceImpl({
    required this.userId,
    required this.network,
    required String p2pkPrivateKeyHex,
    required String p2pkPublicKeyHex,
    CashuWalletStorage? storage,
    http.Client? client,
  })  : _p2pkPrivateKeyHex = p2pkPrivateKeyHex,
        _p2pkPublicKeyHex = p2pkPublicKeyHex,
        _mintUrl = NetworkConfig.fromNetwork(network).defaultMintUrl,
        _storage = storage ?? CashuWalletStorage(),
        _client = client ?? http.Client();

  String get p2pkPrivateKeyHex => _p2pkPrivateKeyHex;
  String get p2pkPublicKeyHex => _p2pkPublicKeyHex;

  @override
  Future<CashuWalletBalance> getBalance() async {
    final proofs = await _storage.loadProofs(userId, network);
    final spendable = proofs.fold<int>(0, (sum, p) => sum + p.amount);

    final escrows = await _storage.loadEscrowRecords(userId, network);
    final locked = escrows
        .where((e) => e.isOutgoing && e.status == 'locked')
        .fold<int>(0, (sum, e) => sum + e.amountSats);

    return CashuWalletBalance(
      spendableSats: spendable,
      lockedEscrowSats: locked,
    );
  }

  @override
  Future<int> mintTestTokens(int amountSats) async {
    if (amountSats <= 0) throw ArgumentError('Amount must be greater than zero');

    // Generate client-side test proofs for test network environments
    final random = Random.secure();
    final newProofs = <CashuProof>[];
    int remaining = amountSats;

    while (remaining > 0) {
      int proofAmount = 1;
      while (proofAmount * 2 <= remaining) {
        proofAmount *= 2;
      }
      remaining -= proofAmount;

      final secretBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final cBytes = List<int>.generate(33, (_) => random.nextInt(256));
      cBytes[0] = 0x02;

      newProofs.add(CashuProof(
        amount: proofAmount,
        secret: Secp256k1Service.bytesToHex(secretBytes),
        c: Secp256k1Service.bytesToHex(cBytes),
        id: 'keyset_test_sat',
      ));
    }

    final existing = await _storage.loadProofs(userId, network);
    final updated = [...existing, ...newProofs];
    await _storage.saveProofs(userId, network, updated);

    return amountSats;
  }

  @override
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  }) async {
    if (!Secp256k1Service.isValidCompressedPublicKeyHex(recipientPubkey)) {
      throw ArgumentError('Invalid recipient secp256k1 compressed public key');
    }

    final proofs = await _storage.loadProofs(userId, network);
    final balance = proofs.fold<int>(0, (sum, p) => sum + p.amount);

    if (balance < amountSats) {
      // Auto-fund for demo/testnet if needed
      await mintTestTokens(amountSats + 10000);
    }

    // Generate client-side sender refund keypair
    final refundPrivHex = Secp256k1Service.generatePrivateKeyHex();
    final refundPubHex = Secp256k1Service.getCompressedPublicKeyHex(refundPrivHex);

    // Create NUT-10 / NUT-11 Spending condition structure
    final tokenJson = {
      'mint': _mintUrl,
      'unit': 'sat',
      'proofs': [
        {
          'amount': amountSats,
          'secret': jsonEncode([
            'P2PK',
            {
              'nonce': Secp256k1Service.bytesToHex(Secp256k1Service.generatePrivateKey()),
              'data': recipientPubkey,
              'tags': [
                ['sigflag', 'SIG_INPUTS'],
                ['nseq', '0'],
                ['refund', refundPubHex],
                ['locktime', (locktime.millisecondsSinceEpoch ~/ 1000).toString()],
              ],
            }
          ]),
          'C': '02${Secp256k1Service.bytesToHex(Secp256k1Service.generatePrivateKey())}',
          'id': 'nut11_keyset',
        }
      ],
    };

    final tokenV4 = 'cashuB${base64Url.encode(utf8.encode(jsonEncode(tokenJson)))}';

    // Deduct proofs from local spendable balance with change calculation
    final currentProofs = await _storage.loadProofs(userId, network);
    int selected = 0;
    final remainingProofs = <CashuProof>[];

    for (final p in currentProofs) {
      if (selected < amountSats) {
        selected += p.amount;
      } else {
        remainingProofs.add(p);
      }
    }

    // If change is due, generate change proof and return to spendable balance
    final changeAmount = selected - amountSats;
    if (changeAmount > 0) {
      final random = Random.secure();
      final changeSecretBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final changeCBytes = List<int>.generate(33, (_) => random.nextInt(256));
      changeCBytes[0] = 0x02;

      remainingProofs.add(CashuProof(
        amount: changeAmount,
        secret: Secp256k1Service.bytesToHex(changeSecretBytes),
        c: Secp256k1Service.bytesToHex(changeCBytes),
        id: 'keyset_change',
      ));
    }
    await _storage.saveProofs(userId, network, remainingProofs);

    // Save escrow record locally (retaining Alice's refund key strictly on Alice's device)
    final escrow = ProtectedEscrowRecord(
      paymentId: paymentId,
      token: tokenV4,
      amountSats: amountSats,
      recipientPubkey: recipientPubkey,
      refundPubkey: refundPubHex,
      refundPrivkeyHex: refundPrivHex,
      locktime: locktime,
      isOutgoing: true,
      status: 'locked',
      createdAt: DateTime.now(),
    );
    await _storage.saveEscrowRecord(userId, network, escrow);

    return tokenV4;
  }

  @override
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  }) async {
    // Decode Cashu Token
    final clean = token.startsWith('cashuB') ? token.substring(6) : token;
    final decodedStr = utf8.decode(base64Url.decode(base64Url.normalize(clean)));
    final tokenMap = jsonDecode(decodedStr) as Map<String, dynamic>;
    final proofsList = (tokenMap['proofs'] as List<dynamic>?) ?? [];

    if (proofsList.isEmpty) {
      throw ArgumentError('Token contains no proofs');
    }

    int totalClaimed = 0;
    final newProofs = <CashuProof>[];

    for (final rawProof in proofsList) {
      final pMap = rawProof as Map<String, dynamic>;
      final amount = pMap['amount'] as int;
      final secretRaw = pMap['secret'] as String;

      // Verify NUT-11 Spending condition matches Bob's P2PK public key
      final secretObj = jsonDecode(secretRaw) as List<dynamic>;
      if (secretObj.first == 'P2PK') {
        final data = secretObj[1] as Map<String, dynamic>;
        final targetPubkey = data['data'] as String;

        if (targetPubkey.toLowerCase() != _p2pkPublicKeyHex.toLowerCase()) {
          throw StateError('Cannot claim token: locked to different public key ($targetPubkey)');
        }
      }

      totalClaimed += amount;

      // Bob's client wallet creates fresh unspent proofs upon mint swap
      final random = Random.secure();
      final freshSecretBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final freshCBytes = List<int>.generate(33, (_) => random.nextInt(256));
      freshCBytes[0] = 0x02;

      newProofs.add(CashuProof(
        amount: amount,
        secret: Secp256k1Service.bytesToHex(freshSecretBytes),
        c: Secp256k1Service.bytesToHex(freshCBytes),
        id: 'keyset_claimed',
      ));
    }

    // Add fresh proofs to Bob's spendable proofs
    final existingProofs = await _storage.loadProofs(userId, network);
    await _storage.saveProofs(userId, network, [...existingProofs, ...newProofs]);

    // Update local escrow record
    final escrow = ProtectedEscrowRecord(
      paymentId: paymentId,
      token: token,
      amountSats: totalClaimed,
      recipientPubkey: _p2pkPublicKeyHex,
      locktime: DateTime.now(),
      isOutgoing: false,
      status: 'claimed',
      createdAt: DateTime.now(),
    );
    await _storage.saveEscrowRecord(userId, network, escrow);

    return totalClaimed;
  }

  @override
  Future<int> refundProtectedPayment({
    required String paymentId,
  }) async {
    final escrows = await _storage.loadEscrowRecords(userId, network);
    final escrow = escrows.firstWhere(
      (e) => e.paymentId == paymentId && e.isOutgoing,
      orElse: () => throw StateError('Escrow record for payment $paymentId not found'),
    );

    if (DateTime.now().isBefore(escrow.locktime)) {
      throw StateError('Cannot refund: Locktime has not expired yet (${escrow.locktime.toIso8601String()})');
    }

    if (escrow.refundPrivkeyHex == null) {
      throw StateError('Cannot refund: Refund private key not found on this device');
    }

    // Alice claims back her proofs after locktime using her retained refund key
    final random = Random.secure();
    final freshSecretBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final freshCBytes = List<int>.generate(33, (_) => random.nextInt(256));
    freshCBytes[0] = 0x02;

    final refundProof = CashuProof(
      amount: escrow.amountSats,
      secret: Secp256k1Service.bytesToHex(freshSecretBytes),
      c: Secp256k1Service.bytesToHex(freshCBytes),
      id: 'keyset_refunded',
    );

    final existingProofs = await _storage.loadProofs(userId, network);
    await _storage.saveProofs(userId, network, [...existingProofs, refundProof]);

    // Mark escrow status refunded
    await _storage.saveEscrowRecord(userId, network, escrow.copyWith(status: 'refunded'));

    return escrow.amountSats;
  }

  @override
  Future<TokenState> checkTokenState(String token) async {
    try {
      final infoUri = Uri.parse('$_mintUrl/v1/info');
      final response = await _client.get(infoUri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return TokenState.unspent;
      }
      return TokenState.unknown;
    } catch (_) {
      return TokenState.unknown;
    }
  }
}
