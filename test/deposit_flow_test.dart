import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/wallet_policy.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/receive/domain/deposit_controller.dart';

final class _FakeWallet implements CashuWalletService {
  final Map<int, Completer<MintQuoteResult>> quoteRequests = {};
  var createMintQuoteCalls = 0;
  var mintQuoteCalls = 0;
  MintQuoteStatusResult quoteStatus = const MintQuoteStatusResult(
    state: 'UNPAID',
    isPaid: false,
    status: MintQuoteStatus.unpaid,
  );

  @override
  Future<MintQuoteResult> createMintQuote(int amountSats) {
    createMintQuoteCalls++;
    return (quoteRequests[amountSats] ??= Completer<MintQuoteResult>()).future;
  }

  void completeQuote(int amountSats, String id) {
    quoteRequests[amountSats]!.complete(
      MintQuoteResult(
        quoteId: id,
        bolt11Invoice: 'lntb_${amountSats}_$id',
        amountSats: amountSats,
      ),
    );
  }

  @override
  Future<MintQuoteStatusResult> checkMintQuoteStatus(String quoteId) async =>
      quoteStatus;

  @override
  Future<int> mintQuote(String quoteId) async {
    mintQuoteCalls++;
    return 2000;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeWallet wallet;
  late DepositController controller;

  setUp(() {
    wallet = _FakeWallet();
    controller = DepositController(
      wallet: wallet,
      policy: const WalletPolicy(NetworkConfig.cashuTest),
      balance: () async => const CashuWalletBalance(
        spendableSats: 1000,
        lockedEscrowSats: 0,
      ),
    );
  });

  tearDown(() => controller.dispose());

  test('opening receive does not create a quote', () async {
    await controller.initialize();
    expect(wallet.createMintQuoteCalls, 0);
    expect(controller.state.phase, DepositPhase.idle);
  });

  test('stale quote response cannot replace the newest amount', () async {
    final first = controller.createQuote(1000);
    final second = controller.createQuote(2000);
    await Future<void>.delayed(Duration.zero);

    wallet.completeQuote(2000, 'new');
    await second;
    wallet.completeQuote(1000, 'old');
    await first;

    expect(controller.state.quote?.quoteId, 'new');
    expect(controller.state.amountSats, 2000);
  });

  test('controller applies projected balance cap before requesting quote',
      () async {
    final capped = DepositController(
      wallet: wallet,
      policy: const WalletPolicy(NetworkConfig.mainnetPilot),
      balance: () async => const CashuWalletBalance(
        spendableSats: 9000,
        lockedEscrowSats: 0,
      ),
    );
    addTearDown(capped.dispose);

    await expectLater(
      capped.createQuote(1001),
      throwsA(isA<WalletPolicyViolation>()),
    );
    expect(wallet.createMintQuoteCalls, 0);
  });

  test('paid quote mints once and issued quote is treated as complete',
      () async {
    final quoteFuture = controller.createQuote(2000);
    await Future<void>.delayed(Duration.zero);
    wallet.completeQuote(2000, 'quote_2');
    await quoteFuture;
    wallet.quoteStatus = const MintQuoteStatusResult(
      state: 'PAID',
      isPaid: true,
      status: MintQuoteStatus.paid,
    );

    expect(await controller.checkAndMint(), 2000);
    expect(await controller.checkAndMint(), 2000);
    expect(wallet.mintQuoteCalls, 1);

    final issuedWallet = _FakeWallet();
    final issued = DepositController(
      wallet: issuedWallet,
      policy: const WalletPolicy(NetworkConfig.cashuTest),
      balance: () async => const CashuWalletBalance(
        spendableSats: 0,
        lockedEscrowSats: 0,
      ),
    );
    addTearDown(issued.dispose);
    final issuedQuote = issued.createQuote(500);
    await Future<void>.delayed(Duration.zero);
    issuedWallet.completeQuote(500, 'issued_quote');
    await issuedQuote;
    issuedWallet.quoteStatus = const MintQuoteStatusResult(
      state: 'ISSUED',
      isPaid: false,
      status: MintQuoteStatus.issued,
    );

    expect(await issued.checkAndMint(), isNull);
    expect(issued.state.phase, DepositPhase.issued);
    expect(issuedWallet.mintQuoteCalls, 0);
  });
}
