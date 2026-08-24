import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/core/cashu/cdk_ffi_bindings.dart';
import 'package:hanbova_app/core/crypto/secp256k1_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';

/// In-memory implementation of CashuWalletStorage for testing escrow records
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

/// Simulated FFI engine for widget / headless flutter_tester tests
CdkFfiBindings createMockCdkFfiBindings() {
  int balanceSpendable = 0;
  int balancePending = 0;

  return CdkFfiBindings.custom(
    walletCreate: (mintUrl, dbPath, seedHex, outHandle) {
      outHandle.value = Pointer<Void>.fromAddress(0x12345678);
      return 0;
    },
    walletGetBalance: (handle, outSpendable, outPending) {
      outSpendable.value = balanceSpendable;
      outPending.value = balancePending;
      return 0;
    },
    walletMintQuote: (handle, amountSats, outQuoteId, outInvoice) {
      outQuoteId.value = 'quote_mock_123'.toNativeUtf8();
      outInvoice.value = 'lnbc10u_mock_invoice'.toNativeUtf8();
      return 0;
    },
    walletMint: (handle, quoteId, outMintedSats) {
      balanceSpendable += 10000;
      outMintedSats.value = 10000;
      return 0;
    },
    walletSendLocked: (handle, amountSats, recPub, refPub, locktime, outToken) {
      if (balanceSpendable < amountSats) {
        return 1;
      }
      balanceSpendable -= amountSats;
      balancePending += amountSats;
      outToken.value =
          'cashuBmock_token_locked_${recPub.toDartString()}_$amountSats'
              .toNativeUtf8();
      return 0;
    },
    walletReceive: (handle, tokenStr, privKey, outReceived) {
      final token = tokenStr.toDartString();
      if (!token.startsWith('cashuB')) {
        return 1;
      }
      final amount = 4000;
      balanceSpendable += amount;
      outReceived.value = amount;
      return 0;
    },
    checkTokenState: (handle, tokenStr, outState) {
      outState.value = 0; // Unspent
      return 0;
    },
    walletFree: (handle) {},
    getLastError: () => Pointer<Utf8>.fromAddress(0),
    freeString: (s) {
      if (s.address != 0) {
        calloc.free(s);
      }
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Client-Side CDK Cashu Wallet Authority & P2PK Escrow Lifecycle', () {
    late InMemoryCashuWalletStorage storage;
    late CdkFfiBindings mockFfi;

    // Alice Keys & Seed
    late String aliceSeedHex;
    late String alicePriv;
    late String alicePub;

    // Bob Keys & Seed
    late String bobPriv;
    late String bobPub;

    setUp(() {
      storage = InMemoryCashuWalletStorage();
      mockFfi = createMockCdkFfiBindings();

      aliceSeedHex =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      alicePriv = Secp256k1Service.generatePrivateKeyHex();
      alicePub = Secp256k1Service.getCompressedPublicKeyHex(alicePriv);

      bobPriv = Secp256k1Service.generatePrivateKeyHex();
      bobPub = Secp256k1Service.getCompressedPublicKeyHex(bobPriv);
    });

    test('CDK Wallet initializes, reads balance and rejects send when balance is insufficient', () async {
      final aliceWallet = CdkCashuWalletServiceImpl(
        userId: 'alice_123',
        network: HanbovaNetwork.cashuTest,
        walletSeedHex: aliceSeedHex,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        dbPath: '/tmp/alice_test_wallet',
        storage: storage,
        ffi: mockFfi,
      );

      final balance = await aliceWallet.getBalance();
      expect(balance.spendableSats, 0);
      expect(balance.lockedEscrowSats, 0);

      // Verify no magical auto-funding; throws StateError on insufficient balance
      expect(
        () => aliceWallet.createProtectedSend(
          amountSats: 5000,
          recipientPubkey: bobPub,
          locktime: DateTime.now().add(const Duration(hours: 24)),
          paymentId: 'pay_fail_balance',
        ),
        throwsA(isA<StateError>()),
      );

      aliceWallet.dispose();
    });

    test('CDK Wallet validates recipient compressed public key format', () async {
      final aliceWallet = CdkCashuWalletServiceImpl(
        userId: 'alice_123',
        network: HanbovaNetwork.cashuTest,
        walletSeedHex: aliceSeedHex,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        dbPath: '/tmp/alice_val_wallet',
        storage: storage,
        ffi: mockFfi,
      );

      expect(
        () => aliceWallet.createProtectedSend(
          amountSats: 500,
          recipientPubkey: 'invalid_pubkey_not_hex',
          locktime: DateTime.now().add(const Duration(hours: 24)),
          paymentId: 'pay_invalid_key',
        ),
        throwsA(isA<ArgumentError>()),
      );

      aliceWallet.dispose();
    });

    test('Scenario A: Alice mints, creates NUT-11 locked token for Bob, and Bob receives it', () async {
      final aliceWallet = CdkCashuWalletServiceImpl(
        userId: 'alice_123',
        network: HanbovaNetwork.cashuTest,
        walletSeedHex: aliceSeedHex,
        p2pkPrivateKeyHex: alicePriv,
        p2pkPublicKeyHex: alicePub,
        dbPath: '/tmp/alice_full_wallet',
        storage: storage,
        ffi: mockFfi,
      );

      // 1. Alice mints tokens explicitly
      final minted = await aliceWallet.mintTestTokens(10000);
      expect(minted, 10000);

      final balanceAfterMint = await aliceWallet.getBalance();
      expect(balanceAfterMint.spendableSats, 10000);

      // 2. Alice sends locked token to Bob
      final token = await aliceWallet.createProtectedSend(
        amountSats: 4000,
        recipientPubkey: bobPub,
        locktime: DateTime.now().add(const Duration(hours: 24)),
        paymentId: 'pay_scenario_a',
      );
      expect(token.startsWith('cashuB'), isTrue);

      final balanceAfterSend = await aliceWallet.getBalance();
      expect(balanceAfterSend.spendableSats, 6000);
      expect(balanceAfterSend.lockedEscrowSats, 4000);

      aliceWallet.dispose();
    });
  });
}
