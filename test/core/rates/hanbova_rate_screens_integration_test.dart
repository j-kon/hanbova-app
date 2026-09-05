import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/rates/hanbova_rate.dart';
import 'package:hanbova_app/core/rates/hanbova_rate_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/widgets/hanbova_rate_card.dart';
import 'package:hanbova_app/features/conversion/presentation/conversion_flow_screen.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/spend/presentation/payment_confirmation_sheet.dart';

class FakeRateNotifier extends StateNotifier<HanbovaRateState>
    implements HanbovaRateNotifier {
  FakeRateNotifier(super.initialState);

  @override
  Future<void> fetchRate({
    bool silent = false,
    String market = 'NG',
    String asset = 'USDT',
    String currency = 'NGN',
  }) async {}

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  final testRate = HanbovaRate(
    market: 'NG',
    base: 'USD',
    quote: 'NGN',
    display: r'$1 = ₦1,365.00',
    settlementAsset: 'USDT',
    rate: 1365.00,
    provider: 'bitnob',
    isLive: true,
    isStale: false,
    updatedAt: DateTime.now(),
  );

  Widget buildTestScreen(Widget screen) {
    return ProviderScope(
      overrides: [
        hanbovaRateProvider.overrideWith(
          (ref) => FakeRateNotifier(
            HanbovaRateState(
              status: HanbovaRateStatus.live,
              rate: testRate,
            ),
          ),
        ),
        demoModeProvider.overrideWith((ref) {
          final notifier = DemoModeNotifier();
          if (notifier.state.isEnabled) {
            notifier.toggleDemoMode();
          }
          return notifier;
        }),
        cashuBalanceProvider.overrideWith(
          (ref) => Future.value(
            const CashuWalletBalance(
              spendableSats: 1500000,
              lockedEscrowSats: 300000,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: screen,
      ),
    );
  }

  group('HanbovaRate Screen Integrations', () {
    testWidgets('HomeScreen integrates and displays HanbovaRateCard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestScreen(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(HanbovaRateCard), findsOneWidget);
      expect(find.text('Hanbova Rate'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
      expect(find.text('USDT → NGN'), findsOneWidget);
    });

    testWidgets('MoneyScreen integrates and displays HanbovaRateCard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestScreen(const MoneyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(HanbovaRateCard), findsOneWidget);
      expect(find.text('Hanbova Rate'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
      expect(find.text('USDT → NGN'), findsOneWidget);
    });

    testWidgets('ConversionFlowScreen integrates and displays HanbovaRateCard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestScreen(const ConversionFlowScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(HanbovaRateCard), findsOneWidget);
      expect(find.text('Hanbova Rate'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
    });

    testWidgets(
        'PaymentConfirmationSheet renders inline HanbovaRateCard for NGN',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestScreen(
          Scaffold(
            body: PaymentConfirmationSheet(
              title: 'Confirm Airtime Purchase',
              billerName: 'MTN Nigeria',
              accountReference: '08012345678',
              fiatAmount: 1000.0,
              fiatCurrency: 'NGN',
              amountSats: 730,
              serviceIcon: Icons.phone_android_rounded,
              onConfirm: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HanbovaRateCard), findsOneWidget);
      expect(find.text('Hanbova Rate:'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
    });
  });
}
