import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/profile/providers/profile_provider.dart';
import 'package:hanbova_app/features/spend/presentation/pay_hub_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Theme (Dark and Light) & Enhanced Navbar Action Button Tests', () {
    test('1. HanbovaColors has distinct color palettes for Dark and Light themes', () {
      final darkColors = AppTheme.darkTheme.extension<HanbovaColors>()!;
      final lightColors = AppTheme.lightTheme.extension<HanbovaColors>()!;

      // Backgrounds differ
      expect(darkColors.background, isNot(equals(lightColors.background)));
      expect(darkColors.surfaceCard, isNot(equals(lightColors.surfaceCard)));
      expect(darkColors.textPrimary, isNot(equals(lightColors.textPrimary)));

      // Dark theme uses dark background and light text
      expect(darkColors.background, AppColors.darkBackground);
      expect(darkColors.textPrimary, AppColors.darkTextPrimary);

      // Light theme uses light background and dark text
      expect(lightColors.background, AppColors.lightBackground);
      expect(lightColors.textPrimary, AppColors.lightTextPrimary);

      // Brand primary is consistent
      expect(darkColors.primary, lightColors.primary);
    });

    testWidgets('2. Navbar Center Action Button exists and opens 8-feature Action Sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('HOME'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/activity', builder: (_, __) => const Scaffold(body: Text('ACTIVITY'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/money', builder: (_, __) => const Scaffold(body: Text('MONEY'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: Text('PROFILE'))),
              ]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.darkTheme,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Center Action Button exists
      final centerBtn = find.byKey(const Key('navbar_center_action_button'));
      expect(centerBtn, findsOneWidget);

      // Tap Center Action Button
      await tester.tap(centerBtn);
      await tester.pumpAndSettle();

      // Verify all 8 features appear
      expect(find.text('Pay Everyday Bills'), findsOneWidget);
      expect(find.text('Send Instant'), findsOneWidget);
      expect(find.text('Send Protected'), findsOneWidget);
      expect(find.text('Receive Bitcoin'), findsOneWidget);
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Request Money'), findsOneWidget);
      expect(find.text('Roam Mode'), findsOneWidget);
      expect(find.text('Cashu E-Cash'), findsOneWidget);
    });

    testWidgets('3. HomeScreen renders cleanly in both Dark and Light mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      // 3a. Dark mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            profileProvider.overrideWith((ref) => ProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_rail_send')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_receive')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_protected')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_scan')), findsOneWidget);

      // 3b. Light mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            profileProvider.overrideWith((ref) => ProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_rail_send')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_receive')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_protected')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_scan')), findsOneWidget);
    });

    testWidgets('4. MoneyScreen renders cleanly in both Dark and Light mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      // 4a. Dark mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MoneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Money & Balances'), findsOneWidget);
      expect(find.text('BITCOIN BALANCE'), findsOneWidget);
      expect(find.text('Protected payments'), findsOneWidget);

      // 4b. Light mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MoneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Money & Balances'), findsOneWidget);
      expect(find.text('BITCOIN BALANCE'), findsOneWidget);
      expect(find.text('Protected payments'), findsOneWidget);
    });

    testWidgets('5. PayHubScreen renders cleanly in both Dark and Light mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      // 5a. Dark mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PayHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay'), findsOneWidget);
      expect(find.text('Send Money'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);

      // 5b. Light mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PayHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay'), findsOneWidget);
      expect(find.text('Send Money'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
    });

    testWidgets('6. TransactionsScreen renders cleanly in both Dark and Light mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      // 6a. Dark mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const TransactionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activity'), findsOneWidget);

      // 6b. Light mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currencyProvider.overrideWith((ref) => CurrencyNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TransactionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activity'), findsOneWidget);
    });
  });
}
