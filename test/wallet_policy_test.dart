import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cdk_ffi_bindings.dart';
import 'package:hanbova_app/core/crypto/secp256k1_service.dart';
import 'package:hanbova_app/core/cashu/wallet_policy.dart';
import 'package:hanbova_app/core/network/network_environment.dart';

class CountingCdkFfi {
  int mintQuoteCalls = 0;
  int protectedSendCalls = 0;
  int meltCalls = 0;

  CdkFfiBindings get bindings => CdkFfiBindings.custom(
        walletCreate: (mintUrl, dbPath, seedHex, outHandle) {
          outHandle.value = Pointer<Void>.fromAddress(1);
          return 0;
        },
        walletGetBalance: (handle, outSpendable, outPending) {
          outSpendable.value = 0;
          outPending.value = 0;
          return 0;
        },
        walletMintQuote: (handle, amountSats, outQuoteId, outInvoice) {
          mintQuoteCalls++;
          outQuoteId.value = 'mint_quote'.toNativeUtf8();
          outInvoice.value = 'invoice'.toNativeUtf8();
          return 0;
        },
        checkMintQuoteStatus: (handle, quoteId, outState, outPaid) {
          outState.value = 'UNPAID'.toNativeUtf8();
          outPaid.value = 0;
          return 0;
        },
        walletMint: (handle, quoteId, outMintedSats) {
          outMintedSats.value = 0;
          return 0;
        },
        walletMeltQuote:
            (handle, invoice, outQuoteId, outAmountSats, outFeeReserveSats) {
          outQuoteId.value = 'melt_quote'.toNativeUtf8();
          outAmountSats.value = 5001;
          outFeeReserveSats.value = 0;
          return 0;
        },
        walletMelt: (handle, quoteId, outPaid, outPreimage) {
          meltCalls++;
          outPaid.value = 1;
          outPreimage.value = Pointer<Utf8>.fromAddress(0);
          return 0;
        },
        walletSendLocked:
            (handle, amountSats, recPub, refPub, locktime, outToken) {
          protectedSendCalls++;
          outToken.value = 'cashuBtoken'.toNativeUtf8();
          return 0;
        },
        walletReceive: (handle, token, privateKey, outReceivedSats) {
          outReceivedSats.value = 0;
          return 0;
        },
        checkTokenState: (handle, token, outState) {
          outState.value = 0;
          return 0;
        },
        walletFree: (handle) {},
        getLastError: () => Pointer<Utf8>.fromAddress(0),
        freeString: (value) {
          if (value.address != 0) {
            calloc.free(value);
          }
        },
      );
}

CdkCashuWalletServiceImpl pilotWallet(
  CountingCdkFfi ffi, {
  NetworkConfig networkConfig = NetworkConfig.mainnetPilot,
}) {
  final privateKey = Secp256k1Service.generatePrivateKeyHex();
  return CdkCashuWalletServiceImpl(
    userId: 'policy_test_user',
    network: HanbovaNetwork.mainnet,
    networkConfig: networkConfig,
    walletSeedHex: '00' * 64,
    p2pkPrivateKeyHex: privateKey,
    p2pkPublicKeyHex: Secp256k1Service.getCompressedPublicKeyHex(privateKey),
    balanceProvider: () async =>
        const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0),
    ffi: ffi.bindings,
  );
}

void main() {
  group('WalletPolicy', () {
    test('pilot rejects deposits above the deposit cap', () {
      expect(
        () => WalletPolicy(NetworkConfig.mainnetPilot).validateDeposit(
          amountSats: 10001,
          currentBalanceSats: 0,
        ),
        throwsA(isA<WalletPolicyViolation>()),
      );
    });

    test('pilot rejects deposits that exceed projected wallet balance', () {
      expect(
        () => WalletPolicy(NetworkConfig.mainnetPilot).validateDeposit(
          amountSats: 1001,
          currentBalanceSats: 9000,
        ),
        throwsA(isA<WalletPolicyViolation>()),
      );
    });

    test('pilot rejects sends above 5000 sats', () {
      expect(
        () => WalletPolicy(NetworkConfig.mainnetPilot)
            .validateSend(amountSats: 5001),
        throwsA(isA<WalletPolicyViolation>()),
      );
    });
  });

  group('CdkCashuWalletServiceImpl policy boundary', () {
    test('rejects a policy configuration for a different network', () {
      expect(
        () => pilotWallet(
          CountingCdkFfi(),
          networkConfig: NetworkConfig.cashuTest,
        ),
        throwsArgumentError,
      );
    });

    test('blocks over-cap mint quotes before calling CDK', () async {
      final ffi = CountingCdkFfi();
      final wallet = pilotWallet(ffi);

      await expectLater(
        wallet.createMintQuote(10001),
        throwsA(isA<WalletPolicyViolation>()),
      );

      expect(ffi.mintQuoteCalls, 0);
      wallet.dispose();
    });

    test('blocks over-cap protected sends before calling CDK', () async {
      final ffi = CountingCdkFfi();
      final wallet = pilotWallet(ffi);
      final recipientPrivateKey = Secp256k1Service.generatePrivateKeyHex();
      final recipientPubkey =
          Secp256k1Service.getCompressedPublicKeyHex(recipientPrivateKey);

      await expectLater(
        wallet.createProtectedSend(
          amountSats: 5001,
          recipientPubkey: recipientPubkey,
          locktime: DateTime.now().add(const Duration(hours: 1)),
          paymentId: 'policy_test_payment',
        ),
        throwsA(isA<WalletPolicyViolation>()),
      );

      expect(ffi.protectedSendCalls, 0);
      wallet.dispose();
    });

    test('blocks over-cap melts before calling CDK', () async {
      final ffi = CountingCdkFfi();
      final wallet = pilotWallet(ffi);
      final quote = await wallet.createMeltQuote('lnbc50010n1policytest');

      await expectLater(
        wallet.payMeltQuote(quote.quoteId),
        throwsA(isA<WalletPolicyViolation>()),
      );

      expect(ffi.meltCalls, 0);
      wallet.dispose();
    });
  });
}
