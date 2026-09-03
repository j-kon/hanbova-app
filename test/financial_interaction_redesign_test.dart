import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/app/app.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/spend/presentation/airtime_flow_screen.dart';
import 'package:hanbova_app/features/spend/presentation/data_bundle_flow_screen.dart';
import 'package:hanbova_app/features/spend/presentation/electricity_flow_screen.dart';
import 'package:hanbova_app/features/spend/presentation/pay_hub_screen.dart';
import 'package:hanbova_app/features/spend/presentation/payment_confirmation_sheet.dart';
import 'package:hanbova_app/features/spend/presentation/payment_result_sheets.dart';
import 'package:hanbova_app/features/spend/presentation/tv_subscription_flow_screen.dart';
import 'package:hanbova_app/features/travel/presentation/travel_screen.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';

void main() {
  group('M3B.2.2 Financial Interaction Redesign UX Tests', () {
    testWidgets('1. 5-Tab Shell Navigation persists and switches seamlessly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: HanbovaApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts at Home Tab
      expect(find.byType(HomeScreen), findsOneWidget);

      // Switch to Pay (Tab 1)
      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PayHubScreen), findsOneWidget);

      // Switch to Activity (Tab 2)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Money In'), findsOneWidget);

      // Switch to Travel (Tab 3)
      await tester.tap(find.byIcon(Icons.flight_takeoff_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(TravelScreen), findsOneWidget);

      // Switch to Me (Tab 4)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Recovery Phrase Backup'), findsOneWidget);

      // Return to Home (Tab 0)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
        '2. Home Screen hierarchy renders Attention Hub cards & 4 quick actions',
        (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: HanbovaApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Authoritative Balance Card
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Protected balance'), findsOneWidget);

      // Attention Hub Cards
      expect(find.text('Protected Refund Ready'), findsOneWidget);
      expect(find.text('Payment Processing (Uncertain)'), findsOneWidget);
      expect(find.text('eSIM Low Data (250 MB left)'), findsOneWidget);

      // 4-Button Quick Action Grid
      expect(find.text('Send'), findsWidgets);
      expect(find.text('Receive'), findsWidgets);
      expect(find.text('Pay'), findsWidgets);
      expect(find.text('Scan'), findsWidgets);
    });

    testWidgets(
        '3. Pay Hub renders Spend Market, Pay Again carousel, & Services Grid',
        (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PayHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay & Spend Hub'), findsOneWidget);
      expect(find.text('Pay Again'), findsOneWidget);
      expect(find.text('Mom\'s MTN'), findsOneWidget);
      expect(find.text('Home IKEDC'), findsOneWidget);
      expect(find.text('DStv Compact'), findsOneWidget);
      expect(find.text('Everyday Bills & Utilities'), findsOneWidget);
      expect(find.text('Airtime'), findsOneWidget);
      expect(find.text('Data Bundles'), findsOneWidget);
      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('TV Cables'), findsOneWidget);
      expect(find.text('Internet'), findsOneWidget);
      expect(find.text('Water Bills'), findsOneWidget);
    });

    testWidgets('4. Airtime flow: My Number vs Someone Else & preset amounts', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AirtimeFlowScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy Airtime'), findsOneWidget);
      expect(find.text('My Number'), findsOneWidget);
      expect(find.text('Someone Else'), findsOneWidget);

      // Toggle to Someone Else
      await tester.tap(find.text('Someone Else'));
      await tester.pumpAndSettle();
      expect(find.text('Enter phone number'), findsOneWidget);

      // Presets exist
      expect(find.text('Select Amount'), findsOneWidget);
      expect(find.text('Custom amount'), findsOneWidget);
    });

    testWidgets('5. Data Bundle flow: Daily, Weekly, Monthly packages', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DataBundleFlowScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy Data Bundles'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // Daily items
      expect(find.text('1GB'), findsOneWidget);

      // Switch to Weekly Tab
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(find.text('3.5GB'), findsOneWidget);

      // Switch to Monthly Tab
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('12GB'), findsOneWidget);
    });

    testWidgets('6. Electricity flow: Saved meters & DISCO selection', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ElectricityFlowScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay Electricity'), findsOneWidget);
      expect(find.text('Select Saved Meter'), findsOneWidget);
      expect(find.text('Use a Different Meter Number'), findsOneWidget);

      // Switch to Different Meter Number
      await tester.tap(find.text('Use a Different Meter Number'));
      await tester.pumpAndSettle();
      expect(find.text('Select Distribution Company (DISCO)'), findsOneWidget);
      expect(find.text('Meter / Account Number'), findsOneWidget);
    });

    testWidgets('7. TV Subscription flow: Providers and bouquets', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvSubscriptionFlowScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TV Subscription'), findsOneWidget);
      expect(find.text('DSTV'), findsOneWidget);
      expect(find.text('GOtv'), findsOneWidget);
      expect(find.text('StarTimes'), findsOneWidget);
      expect(find.text('DStv Compact'), findsOneWidget);
    });

    testWidgets('8. Standardized PaymentConfirmationSheet displays breakdown', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentConfirmationSheet(
              title: 'Confirm Airtime Recharge',
              billerName: 'MTN Airtime',
              accountReference: '+234 803 123 4567',
              fiatAmount: 1000.0,
              fiatCurrency: 'NGN',
              amountSats: 1052,
              feeSats: 50,
              serviceIcon: Icons.phone_android_rounded,
              onConfirm: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Airtime Recharge'), findsOneWidget);
      expect(find.text('₦1,000.00'), findsOneWidget);
      expect(find.text('1,052 sats'), findsOneWidget);
      expect(find.text('MTN Airtime'), findsOneWidget);
      expect(find.text('+234 803 123 4567'), findsOneWidget);
      expect(find.text('Bitcoin Wallet'), findsOneWidget);
      expect(find.text('50 sats'), findsOneWidget);
      expect(find.text('1,102 sats'), findsOneWidget); // total
      expect(find.text('Pay 1,102 sats'), findsOneWidget);
    });

    testWidgets(
        '9. Standardized PaymentSuccessSheet displays electricity token & receipt',
        (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleTx = TransactionModel(
        id: 'tx-test-123',
        type: TransactionType.electricity,
        status: TransactionStatus.completed,
        amountSats: 5260,
        recipientOrSender: 'Ikeja Electric (IKEDC)',
        createdAt: DateTime.now(),
        fiatAmount: 5000.0,
        fiatCurrency: 'NGN',
        feeSats: 50,
        billerName: 'Ikeja Electric (IKEDC)',
        accountReference: '04182938192',
        tokenOrPin: '4829-1039-5829-1029-4821',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSuccessSheet(
              transaction: sampleTx,
              billerName: 'Ikeja Electric (IKEDC)',
              accountReference: '04182938192',
              fiatAmount: 5000.0,
              fiatCurrency: 'NGN',
              amountSats: 5260,
              electricityTokenOrPin: '4829-1039-5829-1029-4821',
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Successful'), findsOneWidget);
      expect(find.text('ELECTRICITY RECHARGE TOKEN'), findsOneWidget);
      expect(find.text('4829-1039-5829-1029-4821'), findsOneWidget);
      expect(find.text('Copy Token'), findsOneWidget);
      expect(find.text('View Official Receipt'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('10. Standardized PaymentUncertainSheet displays reassurance', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentUncertainSheet(
              billerName: 'Spectranet LTE Internet',
              accountReference: 'SPEC-55443',
              amountSats: 15000,
              onViewPending: () {},
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Processing'), findsOneWidget);
      expect(find.textContaining('Checking payment status with biller'),
          findsOneWidget);
      expect(find.text('View in Pending Centre'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('11. Demo Mode Persona: Nigeria residence and isolation', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final demoState = container.read(demoModeProvider);
      expect(demoState.isEnabled, isTrue);
      expect(demoState.totalBalanceSats, 2450000);
      expect(demoState.availableBalanceSats, 1800000);
      expect(demoState.protectedWaitingSats, 300000);
      expect(demoState.protectedRefundableSats, 150000);

      // Verify demo transactions contain bills, travel, and uncertain transactions
      expect(
          demoState.demoTransactions
              .any((t) => t.type == TransactionType.electricity),
          isTrue);
      expect(
          demoState.demoTransactions
              .any((t) => t.status == TransactionStatus.uncertain),
          isTrue);
      expect(
          demoState.demoTransactions
              .any((t) => t.type == TransactionType.protectedRefund),
          isTrue);
    });
  });
}
