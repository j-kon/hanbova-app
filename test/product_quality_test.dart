import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/cards/presentation/cards_screen.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'support/memory_transaction_ledger.dart';
import 'package:hanbova_app/features/transactions/presentation/activity_transaction_tile.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final loading in [false, true]) {
    for (final screen in <String, Widget>{
      'Money': const MoneyScreen(),
      'Home': const HomeScreen()
    }.entries) {
      testWidgets(
          '${screen.key} does not report zero balances when wallet is ${loading ? 'loading' : 'unavailable'}',
          (tester) async {
        final container = ProviderContainer(overrides: [
          cashuBalanceProvider.overrideWith((ref) => loading
              ? Completer<CashuWalletBalance>().future
              : Future<CashuWalletBalance>.error(
                  StateError('wallet unavailable'))),
        ]);
        addTearDown(container.dispose);
        container.read(demoModeProvider.notifier).toggleDemoMode();
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.lightTheme, home: screen.value),
        ));
        await tester.pump();
        for (var i = 0; i < 8; i++) {
          expect(find.text('0 sats'), findsNothing);
          expect(find.textContaining('Portfolio Total: 0'), findsNothing);
          expect(find.text('Active'), findsNothing);
          await tester.drag(
              find.byType(Scrollable).first, const Offset(0, -250));
          await tester.pump(const Duration(milliseconds: 300));
        }
      });
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
        'Cards funding is usable with the ${dark ? 'dark' : 'light'} app theme',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const CardsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final fund = find.widgetWithText(ElevatedButton, 'Fund Card');
      await tester.ensureVisible(fund);
      await tester.tap(fund);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('conversion shows both assets without an incoming payment sign',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ActivityTransactionTile(
      transaction: TransactionModel(
          id: 'swap',
          type: TransactionType.btcToUsdtConversion,
          status: TransactionStatus.completed,
          amountSats: 100000,
          sourceAsset: 'BTC',
          sourceAmount: 100000,
          destinationAsset: 'USDT',
          destinationAmount: 64.82,
          recipientOrSender: 'Conversion',
          createdAt: DateTime(2026, 9, 5)),
      currency: FiatCurrency.usd,
      onTap: () {},
    ))));
    expect(find.text('100,000 sats to 64.82 USDT'), findsOneWidget);
    expect(find.textContaining('+100,000'), findsNothing);
  });

  testWidgets('legacy Home privacy is preserved when settings load',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues(
        {'hanbova_balance_visible': 'false'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(privacyProvider);
    await tester.pumpAndSettle();
    expect(container.read(privacyProvider).isBalanceHidden, isTrue);
  });

  for (final entry in {
    'home': const HomeScreen(),
    'money': const MoneyScreen(),
    'activity': const TransactionsScreen()
  }.entries) {
    testWidgets('${entry.key} fits a small phone with large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: entry.value,
      )));
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        final scroll = find.byType(Scrollable).first;
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
    });
  }

  Future<ProviderContainer> showScreen(WidgetTester tester, Widget screen,
      {bool demo = true, bool hidden = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      cashuBalanceProvider.overrideWith((ref) async => const CashuWalletBalance(
          spendableSats: 43210, lockedEscrowSats: 1234)),
    ]);
    addTearDown(container.dispose);
    if (container.read(demoModeProvider).isEnabled != demo) {
      container.read(demoModeProvider.notifier).toggleDemoMode();
    }
    container.read(privacyProvider);
    await tester.pump();
    await container.read(privacyProvider.notifier).setBalanceHidden(hidden);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('Home respects the shared balance privacy setting',
      (tester) async {
    await showScreen(tester, const HomeScreen(), hidden: true);
    expect(find.textContaining('1,250'), findsNothing);
    expect(find.textContaining('43,210'), findsNothing);
    expect(find.byTooltip('Show balances'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Activity visibly distinguishes uncertain payments from completed payments',
      (tester) async {
    final notifier = await createMemoryTransactionsNotifier(initial: [
      TransactionModel(
          id: 'uncertain',
          type: TransactionType.instantSend,
          status: TransactionStatus.uncertain,
          amountSats: 1000,
          recipientOrSender: 'Amina',
          createdAt: DateTime(2026, 9, 5)),
      TransactionModel(
          id: 'completed',
          type: TransactionType.instantSend,
          status: TransactionStatus.completed,
          amountSats: 1000,
          recipientOrSender: 'Bola',
          createdAt: DateTime(2026, 9, 4)),
    ]);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          transactionsProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const TransactionsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Status Uncertain'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('Money uses the wallet balance when demo is disabled',
      (tester) async {
    await showScreen(tester, const MoneyScreen(), demo: false);
    expect(find.text('43,210 sats'), findsWidgets);
    expect(find.textContaining('1,800,000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Money privacy also masks subtitles and portfolio summaries',
      (tester) async {
    await showScreen(tester, const MoneyScreen(), hidden: true);
    final scroll = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      for (final amount in [
        '1,250',
        '750.00',
        '1,800,000',
        '300,000',
        '150,000'
      ]) {
        expect(find.textContaining(amount), findsNothing,
            reason: 'Balance leaked through secondary text: $amount');
      }
      await tester.drag(scroll, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
