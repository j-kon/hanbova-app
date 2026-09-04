import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/wallet_policy.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/send/domain/instant_send_controller.dart';
import 'package:hanbova_app/features/send/domain/lightning_request_parser.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';

final class _FakeWallet implements CashuWalletService {
  var quoteCalls = 0;
  var payCalls = 0;

  @override
  Future<MeltQuoteResult> createMeltQuote(String bolt11Invoice) async {
    quoteCalls++;
    return const MeltQuoteResult(
      quoteId: 'melt_quote_1',
      amountSats: 500,
      feeReserveSats: 5,
    );
  }

  @override
  Future<MeltExecutionResult> payMeltQuote(String quoteId) async {
    payCalls++;
    return const MeltExecutionResult(isPaid: true, preimage: 'secret');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('parser strips lightning URI and enforces active-network prefix', () {
    expect(
      LightningRequestParser.parse(
        'lightning:LNTB1ABC',
        HanbovaNetwork.cashuTest,
      ),
      'lntb1abc',
    );
    expect(
      () => LightningRequestParser.parse(
        'lnbc1main',
        HanbovaNetwork.cashuTest,
      ),
      throwsA(isA<InvalidLightningRequest>()),
    );
  });

  test('prepare creates a quote but does not pay it', () async {
    final wallet = _FakeWallet();
    final controller = _controller(wallet);
    addTearDown(controller.dispose);

    final review = await controller.prepare('lightning:lntb1invoice');

    expect(review.amountSats, 500);
    expect(review.feeReserveSats, 5);
    expect(review.totalSats, 505);
    expect(wallet.payCalls, 0);
  });

  test('confirm revalidates policy and persists paid result', () async {
    final wallet = _FakeWallet();
    final records = <TransactionModel>[];
    final controller = _controller(wallet, records: records);
    addTearDown(controller.dispose);
    final review = await controller.prepare('lntb1invoice');

    final result = await controller.confirm(review);

    expect(result.isPaid, isTrue);
    expect(wallet.payCalls, 1);
    expect(records.single.amountSats, 500);
    expect(records.single.id, 'ln_pay_melt_quote_1');
  });

  test('confirm rejects a quote prepared for another wallet context', () async {
    final wallet = _FakeWallet();
    var context = _cashuTestContext;
    final controller = _controller(
      wallet,
      activeContext: () => context,
    );
    addTearDown(controller.dispose);
    final review = await controller.prepare('lntb1invoice');
    context = const WalletContextKey(
      userId: 'alice',
      network: HanbovaNetwork.mainnet,
      storagePrefix: 'wallet_mainnet_pilot',
    );

    await expectLater(controller.confirm(review), throwsStateError);
    expect(wallet.payCalls, 0);
  });
}

const _cashuTestContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

InstantSendController _controller(
  _FakeWallet wallet, {
  List<TransactionModel>? records,
  WalletContextKey? Function()? activeContext,
}) {
  return InstantSendController(
    wallet: wallet,
    policy: const WalletPolicy(NetworkConfig.cashuTest),
    activeContext: activeContext ?? () => _cashuTestContext,
    persist: (transaction) async => records?.add(transaction),
  );
}
