import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/home/presentation/asset_balance_carousel.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Widget buildTestApp({
    bool demoMode = true,
    bool hidden = false,
    FiatCurrency currency = FiatCurrency.ngn,
    List<String>? pushedRoutes,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/money/bitcoin',
          builder: (context, state) {
            pushedRoutes?.add('/money/bitcoin');
            return const Scaffold(body: Text('Bitcoin Detail Screen'));
          },
        ),
        GoRoute(
          path: '/money/usdt',
          builder: (context, state) {
            pushedRoutes?.add('/money/usdt');
            return const Scaffold(body: Text('USDT Detail Screen'));
          },
        ),
        GoRoute(
          path: '/money/usdc',
          builder: (context, state) {
            pushedRoutes?.add('/money/usdc');
            return const Scaffold(body: Text('USDC Detail Screen'));
          },
        ),
        GoRoute(
          path: '/send',
          builder: (context, state) {
            final asset = state.uri.queryParameters['asset'];
            pushedRoutes?.add('/send?asset=$asset');
            return Scaffold(body: Text('Send Screen $asset'));
          },
        ),
        GoRoute(
          path: '/receive',
          builder: (context, state) {
            final asset = state.uri.queryParameters['asset'];
            pushedRoutes?.add('/receive?asset=$asset');
            return Scaffold(body: Text('Receive Screen $asset'));
          },
        ),
        GoRoute(
          path: '/convert',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            pushedRoutes?.add('/convert?from=$from');
            return Scaffold(body: Text('Convert Screen from $from'));
          },
        ),
        GoRoute(
          path: '/protected-send',
          builder: (context, state) {
            pushedRoutes?.add('/protected-send');
            return const Scaffold(body: Text('Protected Send Screen'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        demoModeProvider.overrideWith((ref) {
          final notifier = DemoModeNotifier();
          if (!demoMode && notifier.state.isEnabled) {
            notifier.toggleDemoMode();
          } else if (demoMode && !notifier.state.isEnabled) {
            notifier.toggleDemoMode();
          }
          return notifier;
        }),
        cashuBalanceProvider.overrideWith(
          (ref) => Future.value(
            const CashuWalletBalance(
              spendableSats: 1800000,
              lockedEscrowSats: 450000,
            ),
          ),
        ),
        privacyProvider.overrideWith((ref) {
          final notifier = PrivacyNotifier();
          if (hidden) {
            notifier.setBalanceHidden(true);
          }
          return notifier;
        }),
        currencyProvider.overrideWith((ref) {
          final notifier = CurrencyNotifier();
          notifier.setCurrency(currency);
          return notifier;
        }),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('AssetBalanceCarousel & Multi-Asset Home Redesign Tests', () {
    testWidgets('1. Initial page is BTC and displays Bitcoin asset card',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true));
      await tester.pumpAndSettle();

      expect(find.byType(AssetBalanceCarousel), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
      expect(find.text('Available to spend'), findsOneWidget);
      expect(find.text('Money in motion'), findsOneWidget);
    });

    testWidgets(
        '2. Swiping BTC -> USDT updates selected asset and displays Tether',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin'), findsOneWidget);

      // Swipe horizontally left to go to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Tether'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.textContaining('1250.00 USDT'), findsOneWidget);
      // Protected motion panel is removed for stablecoin
      expect(find.text('Money in motion'), findsNothing);
    });

    testWidgets('3. Swiping USDT -> USDC displays USD Coin', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true));
      await tester.pumpAndSettle();

      // Swipe to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Swipe to USDC
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('USD Coin'), findsOneWidget);
      expect(find.text('USDC'), findsOneWidget);
      expect(find.textContaining('750.00 USDC'), findsOneWidget);
    });

    testWidgets('4. Swiping back USDC -> USDT -> BTC restores Bitcoin context',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true));
      await tester.pumpAndSettle();

      // Swipe to USDT then USDC
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Swipe back to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tether'), findsOneWidget);

      // Swipe back to BTC
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('Money in motion'), findsOneWidget);
    });

    testWidgets('5. Balance visibility hides all assets with •••••• masks',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true, hidden: true));
      await tester.pumpAndSettle();

      expect(find.text('•••••• BTC'), findsOneWidget);
      expect(find.text('≈ ••••••'), findsWidgets);
      expect(find.textContaining('1800000'), findsNothing);
      expect(find.textContaining('1,800,000'), findsNothing);

      // Swipe to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('•••••• USDT'), findsOneWidget);
      expect(find.textContaining('1250'), findsNothing);

      // Swipe to USDC
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('•••••• USDC'), findsOneWidget);
      expect(find.textContaining('750'), findsNothing);
    });

    testWidgets(
        '6. Display currency affects secondary equivalent only (KES vs NGN)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester
          .pumpWidget(buildTestApp(demoMode: true, currency: FiatCurrency.kes));
      await tester.pumpAndSettle();

      // Primary remains actual BTC amount
      expect(find.textContaining('0.01800000 BTC'), findsOneWidget);
      // Secondary reflects KSh
      expect(find.textContaining('KSh'), findsWidgets);
    });

    testWidgets('7. Tapping BTC card pushes /money/bitcoin', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pushed = <String>[];
      await tester
          .pumpWidget(buildTestApp(demoMode: true, pushedRoutes: pushed));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('carousel_card_btc')));
      await tester.pumpAndSettle();

      expect(pushed, contains('/money/bitcoin'));
      expect(find.text('Bitcoin Detail Screen'), findsOneWidget);
    });

    testWidgets('8. Tapping USDT card pushes /money/usdt', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pushed = <String>[];
      await tester
          .pumpWidget(buildTestApp(demoMode: true, pushedRoutes: pushed));
      await tester.pumpAndSettle();

      // Swipe to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('carousel_card_usdt')));
      await tester.pumpAndSettle();

      expect(pushed, contains('/money/usdt'));
      expect(find.text('USDT Detail Screen'), findsOneWidget);
    });

    testWidgets('9. Tapping USDC card pushes /money/usdc', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pushed = <String>[];
      await tester
          .pumpWidget(buildTestApp(demoMode: true, pushedRoutes: pushed));
      await tester.pumpAndSettle();

      // Swipe to USDC
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('carousel_card_usdc')));
      await tester.pumpAndSettle();

      expect(pushed, contains('/money/usdc'));
      expect(find.text('USDC Detail Screen'), findsOneWidget);
    });

    testWidgets(
        '10. Normal mode displays truthful \$0.00 / Coming soon for stablecoins',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: false));
      await tester.pumpAndSettle();

      // Swipe to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('0.00 USDT'), findsOneWidget);
      expect(find.text('Coming soon'), findsWidgets);
      expect(find.textContaining('1250'), findsNothing);
    });

    testWidgets(
        '11. Protected Send is available when BTC is selected, but swapped for Convert when USDT is selected',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pushed = <String>[];
      await tester
          .pumpWidget(buildTestApp(demoMode: true, pushedRoutes: pushed));
      await tester.pumpAndSettle();

      // On BTC: Protected is visible in top actions
      expect(find.byKey(const Key('action_rail_protected')), findsOneWidget);

      // Swipe to USDT
      await tester.drag(find.byKey(const Key('asset_balance_page_view')),
          const Offset(-400, 0));
      await tester.pumpAndSettle();

      // On USDT: Protected is NOT available (swapped for Convert)
      expect(find.byKey(const Key('action_rail_protected')), findsNothing);
      expect(find.byKey(const Key('action_rail_convert')), findsOneWidget);

      // Tap Send while USDT is selected
      await tester.tap(find.byKey(const Key('action_rail_send')));
      await tester.pumpAndSettle();
      expect(pushed, contains('/send?asset=usdt'));
    });

    testWidgets(
        '12. Vertical Home scrolling works cleanly without horizontal interference',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(demoMode: true));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
