import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/rates/hanbova_rate.dart';
import 'package:hanbova_app/core/rates/hanbova_rate_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/widgets/hanbova_rate_card.dart';

Widget createTestWidget({
  required HanbovaRateState rateState,
  bool isDark = false,
  bool isInline = false,
}) {
  return ProviderScope(
    overrides: [
      hanbovaRateProvider.overrideWith(
        (ref) => FakeRateNotifier(rateState),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Center(
          child: isInline
              ? const HanbovaRateCard.inline()
              : const HanbovaRateCard(),
        ),
      ),
    ),
  );
}

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
  group('HanbovaRateCard Widget Tests', () {
    testWidgets('renders LIVE state correctly in light mode', (tester) async {
      final liveRate = HanbovaRate(
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

      await tester.pumpWidget(createTestWidget(
        rateState: HanbovaRateState(
          status: HanbovaRateStatus.live,
          rate: liveRate,
        ),
        isDark: false,
      ));

      expect(find.text('Hanbova Rate'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
      expect(find.text('USDT → NGN'), findsOneWidget);
      expect(find.text('Updated just now'), findsOneWidget);
    });

    testWidgets('renders LIVE state correctly in dark mode', (tester) async {
      final liveRate = HanbovaRate(
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

      await tester.pumpWidget(createTestWidget(
        rateState: HanbovaRateState(
          status: HanbovaRateStatus.live,
          rate: liveRate,
        ),
        isDark: true,
      ));

      expect(find.text('Hanbova Rate'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
    });

    testWidgets('renders STALE state correctly', (tester) async {
      final staleRate = HanbovaRate(
        market: 'NG',
        base: 'USD',
        quote: 'NGN',
        display: r'$1 = ₦1,365.00',
        settlementAsset: 'USDT',
        rate: 1365.00,
        provider: 'bitnob',
        isLive: false,
        isStale: true,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      );

      await tester.pumpWidget(createTestWidget(
        rateState: HanbovaRateState(
          status: HanbovaRateStatus.stale,
          rate: staleRate,
        ),
      ));

      expect(find.text('Stale'), findsOneWidget);
      expect(find.text('Last updated 4m ago'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
    });

    testWidgets('renders DEMO state correctly', (tester) async {
      final demoRate = HanbovaRate.demo(rate: 1365.00);

      await tester.pumpWidget(createTestWidget(
        rateState: HanbovaRateState(
          status: HanbovaRateStatus.demo,
          rate: demoRate,
        ),
      ));

      expect(find.text('Demo rate'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
      expect(find.text('USDT → NGN'), findsOneWidget);
    });

    testWidgets('renders UNAVAILABLE state with retry button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        rateState: const HanbovaRateState(
          status: HanbovaRateStatus.unavailable,
          rate: null,
          errorMessage: 'Rate temporarily unavailable',
        ),
      ));

      expect(find.text('Rate temporarily unavailable'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders LOADING state', (tester) async {
      await tester.pumpWidget(createTestWidget(
        rateState: const HanbovaRateState.initial(),
      ));

      expect(find.text('Updating…'), findsOneWidget);
      expect(find.text('Fetching latest rate…'), findsOneWidget);
    });

    testWidgets('renders INLINE variant correctly', (tester) async {
      final liveRate = HanbovaRate(
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

      await tester.pumpWidget(createTestWidget(
        rateState: HanbovaRateState(
          status: HanbovaRateStatus.live,
          rate: liveRate,
        ),
        isInline: true,
      ));

      expect(find.text('Hanbova Rate:'), findsOneWidget);
      expect(find.text(r'$1 = ₦1,365.00'), findsOneWidget);
      expect(find.text('USDT → NGN'), findsOneWidget);
    });
  });
}
