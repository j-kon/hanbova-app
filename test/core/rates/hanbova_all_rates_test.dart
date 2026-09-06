import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/rates/hanbova_all_rates_provider.dart';
import 'package:hanbova_app/core/rates/hanbova_rate.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/widgets/hanbova_rate_card.dart';
import 'package:hanbova_app/features/rates/all_rates_screen.dart';
import 'package:hanbova_app/features/spend/presentation/payment_confirmation_sheet.dart';

void main() {
  group('Multi-Market Platform Rates Tests', () {
    test('HanbovaRate.formatDisplay formats all supported currencies correctly',
        () {
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'NGN', rate: 1565.0),
        r'$1 = ₦1,565.00',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'KES', rate: 132.5),
        r'$1 = KSh 132.50',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'GHS', rate: 15.4),
        r'$1 = GH₵ 15.40',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'ZAR', rate: 18.2),
        r'$1 = R 18.20',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'UGX', rate: 3750.0),
        r'$1 = USh 3,750.00',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'RWF', rate: 1310.0),
        r'$1 = RWF 1,310.00',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'TZS', rate: 2680.0),
        r'$1 = TSh 2,680.00',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'USD', rate: 1.0),
        '1 USDT = \$1.00',
      );
    });

    test('HanbovaMarketRateState metadata and conversions work', () {
      final state = HanbovaMarketRateState(
        market: 'KE',
        currency: 'KES',
        status: HanbovaRateStatus.live,
        rate: HanbovaRate(
          market: 'KE',
          base: 'USD',
          quote: 'KES',
          display: r'$1 = KSh 132.50',
          settlementAsset: 'USDT',
          rate: 132.5,
          provider: 'bitnob',
          environment: 'production',
          isLive: true,
          isStale: false,
          updatedAt: DateTime(2026, 9, 6),
        ),
      );

      expect(state.flagEmoji, '🇰🇪');
      expect(state.countryName, 'Kenya');
      expect(state.isAvailable, true);

      final rateState = state.toRateState();
      expect(rateState.status, HanbovaRateStatus.live);
      expect(rateState.rate?.display, r'$1 = KSh 132.50');
      expect(rateState.rate?.market, 'KE');
    });

    test('HanbovaAllRatesState findBy finds by market or currency', () {
      final allState = HanbovaAllRatesState(
        status: HanbovaAllRatesStatus.loaded,
        markets: [
          HanbovaMarketRateState(
            market: 'NG',
            currency: 'NGN',
            status: HanbovaRateStatus.live,
            rate: HanbovaRate.demo(market: 'NG', quote: 'NGN', rate: 1565.0),
          ),
          HanbovaMarketRateState(
            market: 'KE',
            currency: 'KES',
            status: HanbovaRateStatus.live,
            rate: HanbovaRate.demo(market: 'KE', quote: 'KES', rate: 132.5),
          ),
        ],
      );

      expect(allState.findBy(market: 'ke')?.currency, 'KES');
      expect(allState.findBy(currency: 'kes')?.market, 'KE');
      expect(allState.findBy(market: 'NG')?.rate?.rate, 1565.0);
      expect(allState.findBy(market: 'TZ'), isNull);
    });

    testWidgets('HanbovaRateCard scopes to specified currency (KES)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final demoMode = DemoModeNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => demoMode),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: HanbovaRateCard(currency: 'KES'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must display KES rate, NOT NGN!
      expect(find.text(r'$1 = KSh 132.50'), findsOneWidget);
      expect(find.text('USDT → KES'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,565.00'), findsNothing);
    });

    testWidgets('HanbovaRateCard.inline scopes to specified currency (KES)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final demoMode = DemoModeNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => demoMode),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: HanbovaRateCard.inline(currency: 'KES'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hanbova Rate:'), findsOneWidget);
      expect(find.text(r'$1 = KSh 132.50'), findsOneWidget);
      expect(find.text('USDT → KES'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,565.00'), findsNothing);
    });

    testWidgets(
        'PaymentConfirmationSheet renders inline HanbovaRateCard for KES',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final demoMode = DemoModeNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => demoMode),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: PaymentConfirmationSheet(
                title: 'Confirm Airtime Purchase',
                billerName: 'Safaricom Kenya',
                accountReference: '0712345678',
                fiatAmount: 500.0,
                fiatCurrency: 'KES',
                amountSats: 2500,
                serviceIcon: Icons.phone_android_rounded,
                onConfirm: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HanbovaRateCard), findsOneWidget);
      expect(find.text('Hanbova Rate:'), findsOneWidget);
      // Confirms KES rate is shown, NEVER NGN
      expect(find.text(r'$1 = KSh 132.50'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,565.00'), findsNothing);
    });

    testWidgets('AllRatesScreen renders all 8 markets and corridors',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final demoMode = DemoModeNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => demoMode),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AllRatesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Hanbova Rates'), findsOneWidget);
      expect(
          find.text('Demo rates — provider not yet connected'), findsOneWidget);

      // Verify all 8 country names are rendered
      expect(find.text('Nigeria'), findsOneWidget);
      expect(find.text('Kenya'), findsOneWidget);
      expect(find.text('Ghana'), findsOneWidget);
      expect(find.text('South Africa'), findsOneWidget);
      expect(find.text('Uganda'), findsOneWidget);
      expect(find.text('Rwanda'), findsOneWidget);
      expect(find.text('Tanzania'), findsOneWidget);
      expect(find.text('Global (USD)'), findsOneWidget);

      // Verify rates
      expect(find.text(r'$1 = ₦1,565.00'), findsOneWidget);
      expect(find.text(r'$1 = KSh 132.50'), findsOneWidget);
      expect(find.text(r'$1 = GH₵ 15.40'), findsOneWidget);
      expect(find.text(r'$1 = R 18.20'), findsOneWidget);
      expect(find.text(r'$1 = USh 3,750.00'), findsOneWidget);
      expect(find.text(r'$1 = RWF 1,310.00'), findsOneWidget);
      expect(find.text(r'$1 = TSh 2,680.00'), findsOneWidget);
      expect(find.text('1 USDT = \$1.00'), findsOneWidget);
    });
  });
}
