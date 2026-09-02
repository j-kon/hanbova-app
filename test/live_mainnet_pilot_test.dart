// ignore_for_file: avoid_print
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

Future<Map<String, dynamic>> httpPost(String url, Map<String, dynamic> body,
    {String? token}) async {
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

Future<Map<String, dynamic>> httpPut(String url, Map<String, dynamic> body,
    {required String token}) async {
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
    return jsonDecode(responseBody);
  }
  throw StateError('HTTP ${resp.statusCode} for GET $url: $responseBody');
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  HttpOverrides.global = _RealHttpOverrides();

  final runPilot = Platform.environment['HANBOVA_RUN_MAINNET_PILOT'] == 'true';

  test('Mainnet Pilot Live Integration: Minibits Genuine Ecash Flow', () async {
    if (!runPilot) {
      print(
          'Skipping live Mainnet Pilot test. Set HANBOVA_RUN_MAINNET_PILOT=true.');
      return;
    }

    const mintUrl = 'https://mint.minibits.cash/Bitcoin';
    const pilotStoragePrefix = 'wallet_mainnet_pilot';
    const apiBaseUrl = 'http://127.0.0.1:8080/api/v1';

    print('==================================================');
    print('1. VERIFYING MINIBITS MINT CAPABILITIES');
    print('==================================================');
    final mintClient = HttpClient();
    final mintReq = await mintClient.getUrl(Uri.parse('$mintUrl/v1/info'));
    final mintResp = await mintReq.close();
    final mintBody = await mintResp.transform(utf8.decoder).join();
    mintClient.close();
    expect(mintResp.statusCode, equals(200));

    final mintInfo = jsonDecode(mintBody) as Map<String, dynamic>;
    final nuts = mintInfo['nuts'] as Map<String, dynamic>;
    print('Mint Name: ${mintInfo['name']}');
    print('Mint Version: ${mintInfo['version']}');
    print('Mint Pubkey: ${mintInfo['pubkey']}');
    expect(nuts.containsKey('4'), isTrue);
    expect(nuts.containsKey('7'), isTrue);
    expect(nuts.containsKey('10'), isTrue);
    expect(nuts.containsKey('11'), isTrue);
    print('Mint Capabilities: NUT-04, 07, 10, 11 verified!');

    print('==================================================');
    print('2. INITIALIZING STORAGE & KEYPAIRS');
    print('==================================================');
    final storage = InMemoryCashuWalletStorage();
    final x25519 = X25519();
    final envelopeService = EncryptedEnvelopeService();

    // Alice
    final aliceMnemonic = await MnemonicService.generateMnemonic();
    final aliceSeedHex = await MnemonicService.mnemonicToSeedHex(aliceMnemonic);
    final aliceP2pkPriv =
        await CryptoIdentityNotifier.deriveProtectedPaymentPrivHex(
            aliceSeedHex);
    final aliceP2pkPub =
        Secp256k1Service.getCompressedPublicKeyHex(aliceP2pkPriv);
    final aliceTransportKeyPair =
        await CryptoIdentityNotifier.deriveTransportKeyPair(
            aliceSeedHex, x25519);
    final aliceTransportPub = Secp256k1Service.bytesToHex(
        (await aliceTransportKeyPair.extractPublicKey()).bytes);

    // Bob
    final bobMnemonic = await MnemonicService.generateMnemonic();
    final bobSeedHex = await MnemonicService.mnemonicToSeedHex(bobMnemonic);
    final bobP2pkPriv =
        await CryptoIdentityNotifier.deriveProtectedPaymentPrivHex(bobSeedHex);
    final bobP2pkPub = Secp256k1Service.getCompressedPublicKeyHex(bobP2pkPriv);
    final bobTransportKeyPair =
        await CryptoIdentityNotifier.deriveTransportKeyPair(bobSeedHex, x25519);
    final bobTransportPub = Secp256k1Service.bytesToHex(
        (await bobTransportKeyPair.extractPublicKey()).bytes);

    final ts = DateTime.now().millisecondsSinceEpoch;
    final aliceUsername = 'alice_pilot_$ts';
    final bobUsername = 'bob_pilot_$ts';

    // Temp Redb paths for test isolation
    final tempDir = Directory.systemTemp.createTempSync('hanbova_pilot_');
    final aliceDbDir = Directory('${tempDir.path}/alice_pilot');
    final bobDbDir = Directory('${tempDir.path}/bob_pilot');

    final aliceWallet = CdkCashuWalletServiceImpl(
      userId: aliceUsername,
      network: HanbovaNetwork.mainnet,
      walletSeedHex: aliceSeedHex,
      p2pkPrivateKeyHex: aliceP2pkPriv,
      p2pkPublicKeyHex: aliceP2pkPub,
      storagePrefix: pilotStoragePrefix,
      mintUrl: mintUrl,
      dbPath: aliceDbDir.path,
      storage: storage,
    );

    final bobWallet = CdkCashuWalletServiceImpl(
      userId: bobUsername,
      network: HanbovaNetwork.mainnet,
      walletSeedHex: bobSeedHex,
      p2pkPrivateKeyHex: bobP2pkPriv,
      p2pkPublicKeyHex: bobP2pkPub,
      storagePrefix: pilotStoragePrefix,
      mintUrl: mintUrl,
      dbPath: bobDbDir.path,
      storage: storage,
    );

    // Register on local relay backend
    final aliceAuth = await httpPost('$apiBaseUrl/auth/register', {
      'first_name': 'Alice',
      'last_name': 'Pilot',
      'username': aliceUsername,
      'email': '$aliceUsername@hanbova.africa',
      'password': 'Password123!',
      'phone': null,
    });
    final aliceToken = aliceAuth['access_token'] as String;

    final bobAuth = await httpPost('$apiBaseUrl/auth/register', {
      'first_name': 'Bob',
      'last_name': 'Pilot',
      'username': bobUsername,
      'email': '$bobUsername@hanbova.africa',
      'password': 'Password123!',
      'phone': null,
    });
    final bobToken = bobAuth['access_token'] as String;

    await httpPut(
      '$apiBaseUrl/me/payment-keys',
      {
        'protected_payment_pubkey': aliceP2pkPub,
        'transport_encryption_pubkey': aliceTransportPub,
        'wallet_environment': pilotStoragePrefix,
      },
      token: aliceToken,
    );

    await httpPut(
      '$apiBaseUrl/me/payment-keys',
      {
        'protected_payment_pubkey': bobP2pkPub,
        'transport_encryption_pubkey': bobTransportPub,
        'wallet_environment': pilotStoragePrefix,
      },
      token: bobToken,
    );

    print('==================================================');
    print('3. NUT-04 REAL SAT FUNDING (250 SATS)');
    print('==================================================');
    const fundingAmount = 250;
    final envQuoteId = Platform.environment['PILOT_QUOTE_ID'];
    final quote = (envQuoteId != null && envQuoteId.isNotEmpty)
        ? MintQuoteResult(
            quoteId: envQuoteId,
            bolt11Invoice: '',
            amountSats: fundingAmount,
          )
        : await aliceWallet.createMintQuote(fundingAmount);
    print('Generated Minibits Mint Quote ID: ${quote.quoteId}');
    if (quote.bolt11Invoice.isNotEmpty) {
      print('BOLT11 Invoice:\n${quote.bolt11Invoice}');
    }
    print('\n>>> WAITING FOR INVOICE PAYMENT (250 SATS) <<<');

    // Poll for quote payment
    int elapsed = 0;
    bool paid = false;
    while (elapsed < 900) {
      try {
        final status = await aliceWallet.checkMintQuoteStatus(quote.quoteId);
        if (status.state == 'PAID' || status.state == 'ISSUED') {
          paid = true;
          print('\n[✓] Invoice paid at Minibits mint!');
          break;
        }
      } catch (e) {
        print('Transient polling error: $e');
      }
      await Future.delayed(const Duration(seconds: 3));
      elapsed += 3;
      if (elapsed % 15 == 0) {
        print('Polling quote status... (${elapsed}s elapsed)');
      }
    }

    if (!paid) {
      throw StateError('Mint quote was not paid within timeout.');
    }

    final minted = await aliceWallet.mintQuote(quote.quoteId);
    expect(minted, equals(fundingAmount));

    final aliceBal = await aliceWallet.getBalance();
    print(
        'Alice Authoritative Mainnet CDK Balance: ${aliceBal.spendableSats} sats');
    expect(aliceBal.spendableSats, equals(250));

    print('==================================================');
    print('4. SCENARIO A: REAL SAT PROTECTED CLAIM (100 SATS)');
    print('==================================================');
    final locktimeA = DateTime.now().add(const Duration(minutes: 5));

    final intentA = await httpPost(
      '$apiBaseUrl/payment-intents',
      {
        'payment_type': 'protected',
        'amount_sats': 100,
        'recipient_identifier': '@$bobUsername',
        'description': 'Mainnet Pilot Scenario A',
        'expires_in_seconds': 300,
      },
      token: aliceToken,
    );
    final paymentIdA = intentA['id'] as String;

    final tokenA = await aliceWallet.createProtectedSend(
      amountSats: 100,
      recipientPubkey: bobP2pkPub,
      locktime: locktimeA,
      paymentId: paymentIdA,
    );
    print(
        'Created Real-Sat NUT-11 Protected Token: ${tokenA.substring(0, 30)}...');

    final envelopeA = ProtectedPaymentEnvelope(
      paymentId: paymentIdA,
      cashuToken: tokenA,
      mintUrl: mintUrl,
      amountSats: 100,
      senderUsername: aliceUsername,
      recipientUsername: bobUsername,
      locktime: locktimeA.millisecondsSinceEpoch ~/ 1000,
    );
    final encPayloadA = await envelopeService.encryptEnvelope(
      envelope: envelopeA,
      recipientTransportPubkeyHex: bobTransportPub,
    );

    await httpPost(
      '$apiBaseUrl/protected-messages',
      {
        'recipient_username': bobUsername,
        'encrypted_payload': encPayloadA,
        'payload_version': 1,
        'payment_intent_id': paymentIdA,
        'wallet_environment': pilotStoragePrefix,
      },
      token: aliceToken,
    );

    final bobInbox = await httpGet(
      '$apiBaseUrl/protected-messages/inbox',
      token: bobToken,
    ) as List<dynamic>;
    final msgA =
        bobInbox.firstWhere((m) => m['payment_intent_id'] == paymentIdA)
            as Map<String, dynamic>;

    final decEnvelopeA = await envelopeService.decryptEnvelope(
      ciphertextString: msgA['encrypted_payload'] as String,
      recipientKeyPair: bobTransportKeyPair,
    );
    expect(decEnvelopeA.cashuToken, equals(tokenA));

    final claimedAmount = await bobWallet.claimProtectedPayment(
      token: decEnvelopeA.cashuToken,
      paymentId: paymentIdA,
    );
    expect(claimedAmount, equals(100));

    final bobBal = await bobWallet.getBalance();
    print('Bob Spendable Real-Sat Balance: ${bobBal.spendableSats} sats');
    expect(bobBal.spendableSats, equals(100));

    final aliceBalAfterA = await aliceWallet.getBalance();
    print(
        'Alice Spendable Real-Sat Balance: ${aliceBalAfterA.spendableSats} sats');
    expect(aliceBalAfterA.spendableSats, equals(150));

    print('==================================================');
    print('5. SCENARIO B: REAL SAT SENDER REFUND (100 SATS)');
    print('==================================================');
    final locktimeB = DateTime.now().add(const Duration(seconds: 4));

    final intentB = await httpPost(
      '$apiBaseUrl/payment-intents',
      {
        'payment_type': 'protected',
        'amount_sats': 100,
        'recipient_identifier': '@$bobUsername',
        'description': 'Mainnet Pilot Scenario B',
        'expires_in_seconds': 4,
      },
      token: aliceToken,
    );
    final paymentIdB = intentB['id'] as String;

    final tokenB = await aliceWallet.createProtectedSend(
      amountSats: 100,
      recipientPubkey: bobP2pkPub,
      locktime: locktimeB,
      paymentId: paymentIdB,
    );

    // Early refund fails
    expect(
      () async =>
          await aliceWallet.refundProtectedPayment(paymentId: paymentIdB),
      throwsA(isA<StateError>()),
    );
    print('Verified: Early refund rejected before locktime.');

    print('Waiting 6s for locktime expiration...');
    await Future.delayed(const Duration(seconds: 6));

    final refundedAmount = await aliceWallet.refundProtectedPayment(
      paymentId: paymentIdB,
    );
    expect(refundedAmount, equals(100));
    print('Refunded 100 sats back to Alice spendable balance!');

    final aliceBalAfterRefund = await aliceWallet.getBalance();
    print(
        'Alice Balance after Refund: ${aliceBalAfterRefund.spendableSats} sats');
    expect(aliceBalAfterRefund.spendableSats, equals(150));

    // Bob late claim must be rejected
    expect(
      () async => await bobWallet.claimProtectedPayment(
        token: tokenB,
        paymentId: paymentIdB,
      ),
      throwsA(isA<StateError>()),
    );
    print('Verified: Bob late claim rejected (proofs already spent).');

    print('==================================================');
    print('PILOT SUMMARY');
    print('Total Funded: 250 sats');
    print('Alice Remaining: ${aliceBalAfterRefund.spendableSats} sats');
    print('Bob Remaining: ${bobBal.spendableSats} sats');
    print('==================================================');
  }, timeout: Timeout.none);
}
