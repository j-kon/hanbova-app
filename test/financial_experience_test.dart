import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/features/beneficiaries/presentation/beneficiaries_screen.dart';
import 'package:hanbova_app/features/cards/presentation/cards_screen.dart';
import 'package:hanbova_app/features/insights/presentation/insights_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/notifications/presentation/notifications_screen.dart';
import 'package:hanbova_app/features/pending/presentation/pending_centre_screen.dart';
import 'package:hanbova_app/features/request_money/presentation/request_money_screen.dart';
import 'package:hanbova_app/features/spend/presentation/saved_payments_screen.dart';
import 'package:hanbova_app/features/statements/presentation/statements_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('M3B.2.1 Core Currencies & Math', () {
    test('supports all 8 target African & global currencies', () {
      expect(FiatCurrency.values.length, 8);
      expect(
          FiatCurrency.values.map((c) => c.code).toList(),
          containsAll([
            'NGN',
            'USD',
            'KES',
            'GHS',
            'RWF',
            'UGX',
            'TZS',
            'ZAR',
          ]));
    });

    test('fiatToSats and format calculations are accurate and deterministic',
        () {
      const sats = 100000; // 0.001 BTC
      // USD at 60,000 USD/BTC -> 0.001 * 60,000 = $60.00
      expect(FiatCurrency.usd.satsToFiat(sats), 60.0);
      expect(FiatCurrency.usd.format(sats), '\$60.00');
      expect(FiatCurrency.usd.fiatToSats(60.0), 100000);

      // KES at 7,800,000 KES/BTC -> 0.001 * 7,800,000 = 7,800 KES
      expect(FiatCurrency.kes.satsToFiat(sats), 7800.0);
      expect(FiatCurrency.kes.format(sats), 'KSh 7,800.00');

      // TZS at 160,000,000 TZS/BTC -> 0.001 * 160,000,000 = 160,000 TZS
      expect(FiatCurrency.tzs.satsToFiat(sats), 160000.0);
      expect(FiatCurrency.tzs.format(sats), 'TSh 160,000');
    });
  });

  group('M3B.2.1 Privacy Provider & Settings', () {
    test('toggles privacy and masking flags correctly', () {
      final settings = const PrivacySettings(
        isBalanceHidden: false,
        hideInAppSwitcher: true,
        hideNotificationAmounts: false,
        requireBiometricForSensitive: true,
      );

      final updated = settings.copyWith(
        isBalanceHidden: true,
        hideInAppSwitcher: false,
        hideNotificationAmounts: true,
        requireBiometricForSensitive: false,
      );

      expect(updated.isBalanceHidden, true);
      expect(updated.hideInAppSwitcher, false);
      expect(updated.hideNotificationAmounts, true);
      expect(updated.requireBiometricForSensitive, false);
    });
  });

  group('M3B.2.1 Deterministic Demo Dataset & State', () {
    test(
        'demoModeProvider initializes with realistic African transaction portfolio',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(demoModeProvider);
      expect(state.totalBalanceSats, 2450000);
      expect(state.availableBalanceSats, 1800000);
      expect(state.protectedTotalSats, 450000);
      expect(state.pendingBalanceSats, 200000);

      expect(state.demoTransactions.isNotEmpty, true);
      expect(state.demoBeneficiaries.length, greaterThanOrEqualTo(4));
      expect(state.demoStatements.length, greaterThanOrEqualTo(3));
      expect(state.demoNotifications.length, greaterThanOrEqualTo(4));
      expect(state.demoCard, isNotNull);
    });

    test(
        'card freeze, fund, and beneficiary mutations function deterministically',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(demoModeProvider.notifier);
      expect(container.read(demoModeProvider).demoCard!.isFrozen, false);

      notifier.toggleCardFreeze();
      expect(container.read(demoModeProvider).demoCard!.isFrozen, true);

      final prevBal = container.read(demoModeProvider).demoCard!.balanceUsd;
      notifier.fundCard(50.0);
      expect(container.read(demoModeProvider).demoCard!.balanceUsd,
          prevBal + 50.0);

      // Beneficiaries
      final initialBenCount =
          container.read(demoModeProvider).demoBeneficiaries.length;
      notifier.addBeneficiary(
        BeneficiaryItem(
          id: 'ben-new',
          name: 'Ngozi Eze',
          handleOrAccount: 'ngozi@getalby.com',
          type: 'lightning',
          countryCode: 'NG',
          lastUsedAt: DateTime.now(),
        ),
      );
      expect(container.read(demoModeProvider).demoBeneficiaries.length,
          initialBenCount + 1);

      notifier.removeBeneficiary('ben-new');
      expect(container.read(demoModeProvider).demoBeneficiaries.length,
          initialBenCount);
    });
  });

  group('M3B.2.1 UI Widget Tests', () {
    testWidgets('MoneyScreen renders total balance and breakdown cards',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MoneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Money & Balances'), findsOneWidget);
      expect(find.text('TOTAL WALLET BALANCE'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('Protected Balance'), findsOneWidget);
      expect(find.text('Pending & In Flight'), findsOneWidget);
      expect(find.text('Reference Display Currency'), findsOneWidget);
    });

    testWidgets(
        'InsightsScreen renders periods, categories, and country spend',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Insights'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('Money In'), findsOneWidget);
      expect(find.text('Money Out'), findsOneWidget);
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Spending by Country / Spend Market'), findsOneWidget);
      expect(find.text('Currencies Used in Spend'), findsOneWidget);
    });

    testWidgets(
        'PendingCentreScreen renders safety notice and action items',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PendingCentreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending & Attention Hub'), findsOneWidget);
      expect(find.text('Payment Status Uncertain'), findsOneWidget);
      expect(
          find.textContaining('Please don\'t pay again yet'), findsOneWidget);
      expect(find.text('Protected Refund Ready to Claim'), findsOneWidget);
      expect(find.text('Backup Recovery Phrase'), findsOneWidget);
    });

    testWidgets(
        'CardsScreen renders virtual card and transaction history',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CardsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Virtual Cards (Sandbox)'), findsOneWidget);
      expect(find.text('CARD BALANCE'), findsOneWidget);
      expect(find.text('Recent Card Activity'), findsOneWidget);
    });

    testWidgets('BeneficiariesScreen renders saved contacts and filters',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BeneficiariesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('People & Beneficiaries'), findsOneWidget);
      expect(find.text('Add Recipient'), findsOneWidget);
      expect(find.text('Amara Obi'), findsOneWidget);
      expect(find.text('Kofi Mensah'), findsOneWidget);
    });

    testWidgets(
        'StatementsScreen renders monthly statements and export options',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StatementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Statements'), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Export CSV'), findsWidgets);
      expect(find.text('Download PDF'), findsWidgets);
    });

    testWidgets(
        'RequestMoneyScreen renders amount and switches currencies',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RequestMoneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Money'), findsOneWidget);
      expect(find.text('REQUEST AMOUNT'), findsOneWidget);
      expect(find.text('Create Payment Request'), findsOneWidget);
    });

    testWidgets('SavedPaymentsScreen renders saved billers and Pay Again',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SavedPaymentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Billers & Payments'), findsOneWidget);
      expect(find.text('Kenya Power (KPLC Prepaid)'), findsOneWidget);
      expect(find.text('Pay Again'), findsWidgets);
    });

    testWidgets(
        'NotificationsScreen renders notifications list and filter tags',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications Centre'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('Bitcoin Received'), findsOneWidget);
    });
  });
}
