import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/core/crypto/secp256k1_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';

/// In-memory implementation of CashuWalletStorage for testing
class InMemoryCashuWalletStorage extends CashuWalletStorage {
  final Map<String, List<CashuProof>> _proofs = {};
  final Map<String, List<ProtectedEscrowRecord>> _escrows = {};

  @override
  Future<List<CashuProof>> loadProofs(String userId, HanbovaNetwork network) async {
    return _proofs['${userId}_${network.name}'] ?? [];
  }

  @override
  Future<void> saveProofs(String userId, HanbovaNetwork network, List<CashuProof> proofs) async {
    _proofs['${userId}_${network.name}'] = List.from(proofs);
  }

  @override
  Future<List<ProtectedEscrowRecord>> loadEscrowRecords(String userId, HanbovaNetwork network) async {
    return _escrows['${userId}_${network.name}'] ?? [];
  }

  @override
  Future<void> saveEscrowRecord(String userId, HanbovaNetwork network, ProtectedEscrowRecord record) async {
    final key = '${userId}_${network.name}';
    final records = _escrows[key] ?? [];
    final idx = records.indexWhere((r) => r.paymentId == record.paymentId);
    if (idx >= 0) {
      records[idx] = record;
    } else {
      records.insert(0, record);
    }
    _escrows[key] = records;
  }
}

void main() {
  group('Client-Side Cashu Wallet Authority & P2PK Escrow Lifecycle', () {
    late InMemoryCashuWalletStorage storage;

    // Alice Keys
    late String alicePriv;
    late String alicePub;

    // Bob Keys
    late String bobPriv;
    late String bobPub;

    // Charlie Keys
    late String charliePriv;
    late String charliePub;

    setUp(() {
      storage = InMemoryCashuWalletStorage();

      alicePriv = Secp256k1Service.generatePrivateKeyHex();
      alicePub = Secp256k1Service.getCompressedPublicKeyHex(alicePriv);

      bobPriv = Secp256k1Service.generatePrivateKeyHex();
      bobPub = Secp256k1Service.getCompressedPublicKeyHex(bobPriv);

      charliePriv = Secp256k1Service.generatePrivateKeyHex();
      charliePub = Secp256k1Service.getCompressedPublicKeyHex(charliePriv);
    });

    test('Scenario A: Alice creates NUT-11 escrow for Bob; Bob claims locally; Charlie cannot claim', () async {
      final aliceWallet = ClientCashuWalletServiceImpl(
        userId: 'alice_123',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        storage: storage,
      );

      final bobWallet = ClientCashuWalletServiceImpl(
        userId: 'bob_456',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: bobPriv,
        p2pkPublicKeyHex: bobPub,
        storage: storage,
      );

      final charlieWallet = ClientCashuWalletServiceImpl(
        userId: 'charlie_789',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: charliePriv,
        p2pkPublicKeyHex: charliePub,
        storage: storage,
      );

      // 1. Alice mints 10,000 sats locally
      await aliceWallet.mintTestTokens(10000);
      final aliceInitialBalance = await aliceWallet.getBalance();
      expect(aliceInitialBalance.spendableSats, 10000);

      // 2. Alice creates protected send locked to Bob's genuine compressed secp256k1 public key
      final locktime = DateTime.now().add(const Duration(hours: 24));
      const paymentId = 'pay_test_001';

      final token = await aliceWallet.createProtectedSend(
        amountSats: 4000,
        recipientPubkey: bobPub,
        locktime: locktime,
        paymentId: paymentId,
      );

      expect(token.startsWith('cashuB'), isTrue);

      // Alice's spendable balance decreases and locked balance increases
      final aliceAfterSend = await aliceWallet.getBalance();
      expect(aliceAfterSend.spendableSats, 6000);
      expect(aliceAfterSend.lockedEscrowSats, 4000);

      // 3. Charlie tries to claim Bob's token and fails
      expect(
        () => charlieWallet.claimProtectedPayment(token: token, paymentId: paymentId),
        throwsA(isA<StateError>()),
      );
      final charlieBalance = await charlieWallet.getBalance();
      expect(charlieBalance.spendableSats, 0);

      // 4. Bob claims token locally with his genuine P2PK key
      final claimedAmount = await bobWallet.claimProtectedPayment(token: token, paymentId: paymentId);
      expect(claimedAmount, 4000);

      final bobBalance = await bobWallet.getBalance();
      expect(bobBalance.spendableSats, 4000);
    });

    test('Scenario B: Alice creates protected send with expired locktime; Alice refunds locally', () async {
      final aliceWallet = ClientCashuWalletServiceImpl(
        userId: 'alice_123',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        storage: storage,
      );

      await aliceWallet.mintTestTokens(10000);

      // Locktime in the past
      final expiredLocktime = DateTime.now().subtract(const Duration(hours: 1));
      const paymentId = 'pay_test_refund_002';

      await aliceWallet.createProtectedSend(
        amountSats: 3000,
        recipientPubkey: bobPub,
        locktime: expiredLocktime,
        paymentId: paymentId,
      );

      final balanceAfterSend = await aliceWallet.getBalance();
      expect(balanceAfterSend.spendableSats, 7000);

      // Alice executes client-side refund using her retained refund key
      final refundedAmount = await aliceWallet.refundProtectedPayment(paymentId: paymentId);
      expect(refundedAmount, 3000);

      final balanceAfterRefund = await aliceWallet.getBalance();
      expect(balanceAfterRefund.spendableSats, 10000);
    });

    test('App restart persistence: Wallet proofs and refund capability persist across app restarts', () async {
      // Session 1: Alice creates an escrow
      final aliceSession1 = ClientCashuWalletServiceImpl(
        userId: 'alice_persisted',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        storage: storage,
      );

      await aliceSession1.mintTestTokens(5000);
      final locktime = DateTime.now().subtract(const Duration(minutes: 5));
      const paymentId = 'pay_persist_003';

      await aliceSession1.createProtectedSend(
        amountSats: 2000,
        recipientPubkey: bobPub,
        locktime: locktime,
        paymentId: paymentId,
      );

      // Session 2: App restarts (new wallet instance reading from storage)
      final aliceSession2 = ClientCashuWalletServiceImpl(
        userId: 'alice_persisted',
        network: HanbovaNetwork.cashuTest,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        storage: storage,
      );

      final balanceOnRestart = await aliceSession2.getBalance();
      expect(balanceOnRestart.spendableSats, 3000);

      // Alice can refund in Session 2 because refund key was persisted
      final refunded = await aliceSession2.refundProtectedPayment(paymentId: paymentId);
      expect(refunded, 2000);

      final finalBalance = await aliceSession2.getBalance();
      expect(finalBalance.spendableSats, 5000);
    });
  });
}
