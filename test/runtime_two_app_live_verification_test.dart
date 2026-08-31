import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/core/crypto/crypto_identity_service.dart';
import 'package:hanbova_app/core/crypto/encrypted_envelope_service.dart';
import 'package:hanbova_app/core/crypto/mnemonic_service.dart';
import 'package:hanbova_app/core/crypto/secp256k1_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

class InMemoryCashuWalletStorage extends CashuWalletStorage {
  final Map<String, String> _data = {};

  String _proofsKey(String userId, HanbovaNetwork network,
      {String? storagePrefix}) {
    final prefix =
        storagePrefix ?? NetworkConfig.fromNetwork(network).storagePrefix;
    return 'hanbova_${prefix}_${userId}_spendable_proofs';
  }

  String _escrowsKey(String userId, HanbovaNetwork network,
      {String? storagePrefix}) {
    final prefix =
        storagePrefix ?? NetworkConfig.fromNetwork(network).storagePrefix;
    return 'hanbova_${prefix}_${userId}_escrow_records';
  }

  @override
  Future<List<CashuProof>> loadProofs(String userId, HanbovaNetwork network,
      {String? storagePrefix}) async {
    final key = _proofsKey(userId, network, storagePrefix: storagePrefix);
    final jsonStr = _data[key];
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => CashuProof.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveProofs(
      String userId, HanbovaNetwork network, List<CashuProof> proofs,
      {String? storagePrefix}) async {
    final key = _proofsKey(userId, network, storagePrefix: storagePrefix);
    _data[key] = jsonEncode(proofs.map((p) => p.toJson()).toList());
  }

  @override
  Future<List<ProtectedEscrowRecord>> loadEscrowRecords(
      String userId, HanbovaNetwork network,
      {String? storagePrefix}) async {
    final key = _escrowsKey(userId, network, storagePrefix: storagePrefix);
    final jsonStr = _data[key];
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => ProtectedEscrowRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveEscrowRecord(
      String userId, HanbovaNetwork network, ProtectedEscrowRecord record,
      {String? storagePrefix}) async {
    final records =
        await loadEscrowRecords(userId, network, storagePrefix: storagePrefix);
    final filtered =
        records.where((r) => r.paymentId != record.paymentId).toList();
    filtered.add(record);
    final key = _escrowsKey(userId, network, storagePrefix: storagePrefix);
    _data[key] = jsonEncode(filtered.map((r) => r.toJson()).toList());
  }
}

Future<Map<String, dynamic>> httpPost(
    String url, Map<String, dynamic> body, {String? token}) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse(url));
  req.headers.contentType = ContentType.json;
  req.headers.set('Accept', 'application/json');
  if (token != null) {
    req.headers.set('Authorization', 'Bearer $token');
  }
  req.write(jsonEncode(body));
  final resp = await req.close();
  final responseBody = await resp.transform(utf8.decoder).join();
  client.close();
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
  }
  throw StateError('HTTP ${resp.statusCode} for POST $url: $responseBody');
}

Future<Map<String, dynamic>> httpPut(
    String url, Map<String, dynamic> body, {required String token}) async {
  final client = HttpClient();
  final req = await client.putUrl(Uri.parse(url));
  req.headers.contentType = ContentType.json;
  req.headers.set('Accept', 'application/json');
  req.headers.set('Authorization', 'Bearer $token');
  req.write(jsonEncode(body));
  final resp = await req.close();
  final responseBody = await resp.transform(utf8.decoder).join();
  client.close();
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
  }
  throw StateError('HTTP ${resp.statusCode} for PUT $url: $responseBody');
}

Future<dynamic> httpGet(String url, {required String token}) async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(url));
  req.headers.set('Accept', 'application/json');
  req.headers.set('Authorization', 'Bearer $token');
  final resp = await req.close();
  final responseBody = await resp.transform(utf8.decoder).join();
  client.close();
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
  }
  throw StateError('HTTP ${resp.statusCode} for GET $url: $responseBody');
}

void main() {
  const mintUrl = 'http://127.0.0.1:3338';
  const apiBaseUrl = 'http://127.0.0.1:8080/api/v1';

  group('Milestone 3A.3 - Live Two-App Runtime Verification', () {
    late Directory aliceDbDir;
    late Directory bobDbDir;

    setUp(() {
      aliceDbDir = Directory.systemTemp.createTempSync('alice_wallet_');
      bobDbDir = Directory.systemTemp.createTempSync('bob_wallet_');
    });

    tearDown(() {
      try {
        if (aliceDbDir.existsSync()) aliceDbDir.deleteSync(recursive: true);
        if (bobDbDir.existsSync()) bobDbDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('Scenario A, B, and C against running Nutshell Mint & Hanbova API',
        () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final aliceUsername = 'alice$timestamp';
      final bobUsername = 'bob$timestamp';

      // ----------------------------------------------------
      // 1. GENERATE CRYPTOGRAPHIC IDENTITIES
      // ----------------------------------------------------
      final x25519 = X25519();
      final envelopeService = EncryptedEnvelopeService();

      // Alice Identity
      final aliceMnemonic = await MnemonicService.generateMnemonic();
      final aliceSeedHex =
          await MnemonicService.mnemonicToSeedHex(aliceMnemonic);
      final aliceP2pkPriv =
          await CryptoIdentityNotifier.deriveProtectedPaymentPrivHex(
              aliceSeedHex);
      final aliceP2pkPub =
          Secp256k1Service.getCompressedPublicKeyHex(aliceP2pkPriv);
      final aliceTransportKeyPair =
          await CryptoIdentityNotifier.deriveTransportKeyPair(
              aliceSeedHex, x25519);
      final aliceTransportPubBytes =
          (await aliceTransportKeyPair.extractPublicKey()).bytes;
      final aliceTransportPub =
          Secp256k1Service.bytesToHex(aliceTransportPubBytes);

      // Bob Identity
      final bobMnemonic = await MnemonicService.generateMnemonic();
      final bobSeedHex = await MnemonicService.mnemonicToSeedHex(bobMnemonic);
      final bobP2pkPriv =
          await CryptoIdentityNotifier.deriveProtectedPaymentPrivHex(
              bobSeedHex);
      final bobP2pkPub =
          Secp256k1Service.getCompressedPublicKeyHex(bobP2pkPriv);
      final bobTransportKeyPair =
          await CryptoIdentityNotifier.deriveTransportKeyPair(
              bobSeedHex, x25519);
      final bobTransportPubBytes =
          (await bobTransportKeyPair.extractPublicKey()).bytes;
      final bobTransportPub = Secp256k1Service.bytesToHex(bobTransportPubBytes);

      // ----------------------------------------------------
      // 2. REGISTER & AUTHENTICATE ON BACKEND API
      // ----------------------------------------------------
      // Register Alice
      final aliceAuthData = await httpPost('$apiBaseUrl/auth/register', {
        'email': '$aliceUsername@hanbova.africa',
        'password': 'Password123!',
        'username': aliceUsername,
        'first_name': 'Alice',
        'last_name': 'Sender',
        'phone': null,
      });
      final aliceToken = aliceAuthData['access_token'] as String;
      final aliceUserId = aliceAuthData['user']['id'] as String;

      // Register Bob
      final bobAuthData = await httpPost('$apiBaseUrl/auth/register', {
        'email': '$bobUsername@hanbova.africa',
        'password': 'Password123!',
        'username': bobUsername,
        'first_name': 'Bob',
        'last_name': 'Recipient',
        'phone': null,
      });
      final bobToken = bobAuthData['access_token'] as String;
      final bobUserId = bobAuthData['user']['id'] as String;

      // Publish Alice Keys
      await httpPut(
        '$apiBaseUrl/me/payment-keys',
        {
          'protected_payment_pubkey': aliceP2pkPub,
          'transport_encryption_pubkey': aliceTransportPub,
          'wallet_environment': 'wallet_local',
        },
        token: aliceToken,
      );

      // Publish Bob Keys
      await httpPut(
        '$apiBaseUrl/me/payment-keys',
        {
          'protected_payment_pubkey': bobP2pkPub,
          'transport_encryption_pubkey': bobTransportPub,
          'wallet_environment': 'wallet_local',
        },
        token: bobToken,
      );

      // Alice resolves Bob's payment profile from backend
      final bobProfileData = await httpGet(
        '$apiBaseUrl/users/$bobUsername/payment-profile?environment=wallet_local',
        token: aliceToken,
      );
      expect(bobProfileData['protected_payment_pubkey'], equals(bobP2pkPub));
      expect(bobProfileData['transport_encryption_pubkey'],
          equals(bobTransportPub));

      // ----------------------------------------------------
      // 3. INITIALIZE GENUINE CDK WALLET SERVICES
      // ----------------------------------------------------
      final storage = InMemoryCashuWalletStorage();

      var aliceWallet = CdkCashuWalletServiceImpl(
        userId: aliceUserId,
        network: HanbovaNetwork.local,
        walletSeedHex: aliceSeedHex,
        p2pkPrivateKeyHex: aliceP2pkPriv,
        p2pkPublicKeyHex: aliceP2pkPub,
        storagePrefix: 'wallet_local',
        mintUrl: mintUrl,
        dbPath: aliceDbDir.path,
        storage: storage,
      );

      var bobWallet = CdkCashuWalletServiceImpl(
        userId: bobUserId,
        network: HanbovaNetwork.local,
        walletSeedHex: bobSeedHex,
        p2pkPrivateKeyHex: bobP2pkPriv,
        p2pkPublicKeyHex: bobP2pkPub,
        storagePrefix: 'wallet_local',
        mintUrl: mintUrl,
        dbPath: bobDbDir.path,
        storage: storage,
      );

      // Verify Initial Balances
      final aliceBalInit = await aliceWallet.getBalance();
      final bobBalInit = await bobWallet.getBalance();
      expect(aliceBalInit.spendableSats, equals(0));
      expect(bobBalInit.spendableSats, equals(0));

      // ----------------------------------------------------
      // 4. FUND ALICE WITH 1,000 SATS VIA CDK MINT
      // ----------------------------------------------------
      final mintQuote = await aliceWallet.createMintQuote(1000);
      expect(mintQuote.amountSats, equals(1000));
      expect(mintQuote.quoteId, isNotEmpty);

      final mintedAmount = await aliceWallet.mintQuote(mintQuote.quoteId);
      expect(mintedAmount, equals(1000));

      final aliceBalFunded = await aliceWallet.getBalance();
      expect(aliceBalFunded.spendableSats, equals(1000));

      // ----------------------------------------------------
      // 5. SCENARIO A: REAL PROTECTED CLAIM (ALICE -> BOB)
      // ----------------------------------------------------
      final locktimeA = DateTime.now().add(const Duration(seconds: 30));

      // Alice creates Payment Intent first on Backend to obtain canonical UUID
      final intentA = await httpPost(
        '$apiBaseUrl/payment-intents',
        {
          'payment_type': 'protected',
          'amount_sats': 100,
          'recipient_identifier': '@$bobUsername',
          'description': 'Scenario A Claim Test',
          'expires_in_seconds': 30,
        },
        token: aliceToken,
      );
      final paymentIdA = intentA['id'] as String;

      // Alice creates genuine NUT-11 locked token in CDK
      final tokenA = await aliceWallet.createProtectedSend(
        amountSats: 100,
        recipientPubkey: bobP2pkPub,
        locktime: locktimeA,
        paymentId: paymentIdA,
      );
      expect(tokenA.startsWith('cashu'), isTrue);

      final aliceBalAfterSendA = await aliceWallet.getBalance();
      expect(aliceBalAfterSendA.spendableSats, equals(900));
      final aliceEscrowsA = await storage.loadEscrowRecords(
          aliceUserId, HanbovaNetwork.local,
          storagePrefix: 'wallet_local');
      expect(
          aliceEscrowsA
              .where((e) => e.paymentId == paymentIdA && e.status == 'locked')
              .length,
          equals(1));

      // Alice encrypts envelope for Bob using EncryptedEnvelopeService
      final envelopeA = ProtectedPaymentEnvelope(
        paymentId: paymentIdA,
        cashuToken: tokenA,
        mintUrl: mintUrl,
        amountSats: 100,
        senderUsername: aliceUsername,
        recipientUsername: bobUsername,
        locktime: locktimeA.millisecondsSinceEpoch ~/ 1000,
      );
      final encryptedPayloadA = await envelopeService.encryptEnvelope(
        envelope: envelopeA,
        recipientTransportPubkeyHex: bobTransportPub,
      );

      // Alice relays message via Backend
      await httpPost(
        '$apiBaseUrl/protected-messages',
        {
          'recipient_username': bobUsername,
          'encrypted_payload': encryptedPayloadA,
          'payload_version': 1,
          'payment_intent_id': paymentIdA,
          'wallet_environment': 'wallet_local',
        },
        token: aliceToken,
      );

      // Bob fetches message from Inbox
      final bobInboxData = await httpGet(
        '$apiBaseUrl/protected-messages/inbox',
        token: bobToken,
      ) as List<dynamic>;

      final msgA = bobInboxData.firstWhere(
          (m) => m['payment_intent_id'] == paymentIdA) as Map<String, dynamic>;
      expect(msgA['status'], equals('delivered'));

      // Bob decrypts token payload using his transport keypair
      final decryptedEnvelopeA = await envelopeService.decryptEnvelope(
        ciphertextString: msgA['encrypted_payload'] as String,
        recipientKeyPair: bobTransportKeyPair,
      );
      expect(decryptedEnvelopeA.cashuToken, equals(tokenA));

      // Bob executes genuine CDK P2PK claim
      final claimedAmountA = await bobWallet.claimProtectedPayment(
        token: decryptedEnvelopeA.cashuToken,
        paymentId: paymentIdA,
      );
      expect(claimedAmountA, equals(100));

      final bobBalAfterClaimA = await bobWallet.getBalance();
      expect(bobBalAfterClaimA.spendableSats, equals(100));

      // Verify Alice proofs spent: Alice refund must fail
      expect(
        () async =>
            await aliceWallet.refundProtectedPayment(paymentId: paymentIdA),
        throwsA(isA<StateError>()),
      );

      // Verify Activity Deduplication
      final txNotifier = TransactionsNotifier();
      txNotifier.addTransaction(TransactionModel(
        id: paymentIdA,
        type: TransactionType.protectedClaim,
        status: TransactionStatus.claimable,
        amountSats: 100,
        recipientOrSender: '@$aliceUsername',
        description: 'Incoming Protected Payment',
        createdAt: DateTime.now(),
      ));
      txNotifier.addTransaction(TransactionModel(
        id: paymentIdA,
        type: TransactionType.protectedClaim,
        status: TransactionStatus.completed,
        amountSats: 100,
        recipientOrSender: '@$aliceUsername',
        description: 'Incoming Protected Payment',
        createdAt: DateTime.now(),
      ));
      expect(txNotifier.state.where((t) => t.id == paymentIdA).length,
          equals(1));
      expect(txNotifier.state.firstWhere((t) => t.id == paymentIdA).status,
          equals(TransactionStatus.completed));

      // ----------------------------------------------------
      // 6. SCENARIO B: REAL SENDER REFUND & LATE CLAIM REJECTION
      // ----------------------------------------------------
      final locktimeB = DateTime.now().add(const Duration(seconds: 2));

      // Alice creates Payment Intent B
      final intentB = await httpPost(
        '$apiBaseUrl/payment-intents',
        {
          'payment_type': 'protected',
          'amount_sats': 100,
          'recipient_identifier': '@$bobUsername',
          'description': 'Scenario B Refund Test',
          'expires_in_seconds': 2,
        },
        token: aliceToken,
      );
      final paymentIdB = intentB['id'] as String;

      // Alice locks 100 sats with short 2s locktime
      final tokenB = await aliceWallet.createProtectedSend(
        amountSats: 100,
        recipientPubkey: bobP2pkPub,
        locktime: locktimeB,
        paymentId: paymentIdB,
      );

      final aliceBalAfterSendB = await aliceWallet.getBalance();
      expect(aliceBalAfterSendB.spendableSats, equals(800));

      // Early refund before locktime must fail
      expect(
        () async =>
            await aliceWallet.refundProtectedPayment(paymentId: paymentIdB),
        throwsA(isA<StateError>()),
      );

      // Wait 3 seconds for locktime expiry
      await Future.delayed(const Duration(seconds: 3));

      // Alice refunds after locktime
      final refundedAmountB = await aliceWallet.refundProtectedPayment(
        paymentId: paymentIdB,
      );
      expect(refundedAmountB, equals(100));

      final aliceBalAfterRefundB = await aliceWallet.getBalance();
      expect(aliceBalAfterRefundB.spendableSats, equals(900));

      // Bob attempts late claim -> fails because proofs were spent by Alice refund
      expect(
        () async => await bobWallet.claimProtectedPayment(
          token: tokenB,
          paymentId: paymentIdB,
        ),
        throwsA(isA<StateError>()),
      );

      // ----------------------------------------------------
      // 7. SCENARIO C: REAL RESTART & PROCESS PERSISTENCE
      // ----------------------------------------------------
      final locktimeC = DateTime.now().add(const Duration(seconds: 60));

      // Alice creates Payment Intent C
      final intentC = await httpPost(
        '$apiBaseUrl/payment-intents',
        {
          'payment_type': 'protected',
          'amount_sats': 100,
          'recipient_identifier': '@$bobUsername',
          'description': 'Scenario C Restart Test',
          'expires_in_seconds': 60,
        },
        token: aliceToken,
      );
      final paymentIdC = intentC['id'] as String;

      // Alice creates new protected send
      final tokenC = await aliceWallet.createProtectedSend(
        amountSats: 100,
        recipientPubkey: bobP2pkPub,
        locktime: locktimeC,
        paymentId: paymentIdC,
      );

      final aliceBalBeforeKill = await aliceWallet.getBalance();
      expect(aliceBalBeforeKill.spendableSats, equals(800));
      final aliceEscrowsBeforeKill = await storage.loadEscrowRecords(
          aliceUserId, HanbovaNetwork.local,
          storagePrefix: 'wallet_local');
      expect(
          aliceEscrowsBeforeKill
              .where((e) => e.paymentId == paymentIdC && e.status == 'locked')
              .length,
          equals(1));

      // Simulate complete process termination (dispose & nullify)
      aliceWallet.dispose();
      bobWallet.dispose();

      // Restart Alice with fresh wallet instance pointing to existing Redb directory
      final aliceWalletRestarted = CdkCashuWalletServiceImpl(
        userId: aliceUserId,
        network: HanbovaNetwork.local,
        walletSeedHex: aliceSeedHex,
        p2pkPrivateKeyHex: aliceP2pkPriv,
        p2pkPublicKeyHex: aliceP2pkPub,
        storagePrefix: 'wallet_local',
        mintUrl: mintUrl,
        dbPath: aliceDbDir.path,
        storage: storage,
      );

      final aliceBalRestarted = await aliceWalletRestarted.getBalance();
      expect(aliceBalRestarted.spendableSats, equals(800));
      final aliceEscrowsRestarted = await storage.loadEscrowRecords(
          aliceUserId, HanbovaNetwork.local,
          storagePrefix: 'wallet_local');
      expect(
          aliceEscrowsRestarted
              .where((e) => e.paymentId == paymentIdC && e.status == 'locked')
              .length,
          equals(1));

      // Restart Bob with fresh wallet instance pointing to existing Redb directory
      final bobWalletRestarted = CdkCashuWalletServiceImpl(
        userId: bobUserId,
        network: HanbovaNetwork.local,
        walletSeedHex: bobSeedHex,
        p2pkPrivateKeyHex: bobP2pkPriv,
        p2pkPublicKeyHex: bobP2pkPub,
        storagePrefix: 'wallet_local',
        mintUrl: mintUrl,
        dbPath: bobDbDir.path,
        storage: storage,
      );

      // Bob executes claim after restart -> succeeds!
      final claimedAmountC = await bobWalletRestarted.claimProtectedPayment(
        token: tokenC,
        paymentId: paymentIdC,
      );
      expect(claimedAmountC, equals(100));

      final bobBalAfterClaimC = await bobWalletRestarted.getBalance();
      expect(bobBalAfterClaimC.spendableSats, equals(200));

      aliceWalletRestarted.dispose();
      bobWalletRestarted.dispose();
    });
  });
}
