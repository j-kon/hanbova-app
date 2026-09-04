import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/profile/providers/profile_provider.dart';
import 'package:hanbova_app/features/profile/screens/edit_profile_screen.dart';
import 'package:hanbova_app/features/profile/screens/profile_screen.dart';
import 'package:hanbova_app/features/profile/screens/settings_screen.dart';
import 'package:hanbova_app/features/roam/presentation/roam_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Hanbova M3B.2.2 Navigation, Profile & Roam Mode Tests', () {
    // 1. Bottom navigation architecture: 4 tabs + restored Center Action Button
    testWidgets(
        '1. Bottom navigation architecture has Home, Activity, Action Button, Money, Profile',
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
                GoRoute(
                    path: '/home',
                    builder: (_, __) =>
                        const Scaffold(body: Text('HOME_PAGE'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                    path: '/activity',
                    builder: (_, __) =>
                        const Scaffold(body: Text('ACTIVITY_PAGE'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                    path: '/money',
                    builder: (_, __) =>
                        const Scaffold(body: Text('MONEY_PAGE'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                    path: '/profile',
                    builder: (_, __) =>
                        const Scaffold(body: Text('PROFILE_PAGE'))),
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

      // Verify the 4 labels and Center Action Button exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(
          find.byKey(const Key('navbar_center_action_button')), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify old labels are completely absent from bottom nav
      expect(find.text('Travel'), findsNothing);
      expect(find.text('Me'), findsNothing);

      // Tapping Center Action Button opens action hub sheet with 8 features
      await tester.tap(find.byKey(const Key('navbar_center_action_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pay Everyday Bills'), findsOneWidget);
      expect(find.text('Send Instant'), findsOneWidget);
      expect(find.text('Send Protected'), findsOneWidget);
      expect(find.text('Receive Bitcoin'), findsOneWidget);
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Request Money'), findsOneWidget);
      expect(find.text('Roam Mode'), findsOneWidget);
      expect(find.text('Cashu E-Cash'), findsOneWidget);
    });

    // 2. Restored Action Rail on Home with primary actions immediately visible
    testWidgets(
        '2. Restored Action Rail on Home with Send, Receive, Protected, Scan',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

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

      // Primary actions immediately visible on Action Rail
      expect(find.byKey(const Key('action_rail_send')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_receive')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_protected')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_scan')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_request')), findsOneWidget);
      expect(find.byKey(const Key('action_rail_more')), findsOneWidget);
    });

    // 3. Action Catalogue sheet opened from More
    testWidgets('3. Tapping More opens wider Action Catalogue sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

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

      // Scroll to More horizontally on the action rail and tap
      final moreFinder = find.byKey(const Key('action_rail_more'));
      expect(moreFinder, findsOneWidget);
      await tester.ensureVisible(moreFinder);
      await tester.pumpAndSettle();

      await tester.tap(moreFinder);
      await tester.pumpAndSettle();

      // Verify Action Catalogue opened with full suite
      expect(find.text('Action Catalogue'), findsOneWidget);
      expect(find.text('Data'), findsWidgets);
      expect(find.text('Electricity'), findsWidgets);
      expect(find.text('TV'), findsWidgets);
      expect(find.text('Internet'), findsWidgets);
      expect(find.text('Water'), findsWidgets);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Roam'), findsOneWidget);
    });

    // 4. Home Profile Greeting Header
    testWidgets(
        '4. Home Profile Header displays avatar, Jaykon name, and Nigeria residence',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

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

      expect(find.textContaining('Jeremiah'), findsOneWidget);
      expect(find.text('Nigeria'), findsWidgets);
      expect(find.text('JJ'), findsOneWidget); // User initials avatar
    });

    // 5. Money tab: Authoritative Bitcoin Balance & financial hub
    testWidgets(
        '5. Money tab displays Authoritative Bitcoin Balance and financial experience',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
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
      expect(find.text('Available to spend'), findsOneWidget);
      expect(find.text('Money in motion'), findsOneWidget);
      expect(find.text('Protected payments'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Pending'), 200);
      expect(find.text('Pending'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Insights & Statements'), 200);
      expect(find.text('Insights & Statements'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Statements'), findsOneWidget);
    });

    // 6. Real Profile Screen
    testWidgets(
        '6. Real Profile screen displays avatar, full name, @jaykon, Nigeria, Edit Profile, Settings',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => ProfileNotifier()),
            marketProvider.overrideWith((ref) => MarketNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Jeremiah Jacob'), findsOneWidget);
      expect(find.text('@jaykon'), findsOneWidget);
      expect(find.text('Nigeria'), findsWidgets);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.text('Roam Mode'), findsOneWidget);
    });

    // 7. Edit Profile Screen: Photo options and Identity Verification warning
    testWidgets(
        '7. Edit Profile provides photo actions and protected residence with verification note',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => ProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('IDENTITY & RESIDENCE'), findsOneWidget);
      expect(find.text('Country of Residence'), findsOneWidget);
      expect(
          find.text(
              'Changing your country of residence may require verification.'),
          findsOneWidget);

      // Open Photo options modal
      final changePhotoBtn = find.text('Change Profile Photo');
      expect(changePhotoBtn, findsOneWidget);
      await tester.tap(changePhotoBtn);
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Library'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
    });

    // 8. Settings Screen: All 7 categories
    testWidgets('8. Settings screen contains all 7 categorized sections',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketProvider.overrideWith((ref) => MarketNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('ROAM'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('PRIVACY & SECURITY'), 200);
      expect(find.text('PRIVACY & SECURITY'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('WALLET'), 200);
      expect(find.text('WALLET'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('SUPPORT'), 200);
      expect(find.text('SUPPORT'), findsOneWidget);

      expect(find.text('Help Center'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('About Hanbova'), findsOneWidget);
    });

    // 9. Roam Mode: Initial inactive state & copy
    testWidgets(
        '9. Roam Mode initial state has Status: Off and destination picker',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketProvider.overrideWith((ref) => MarketNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const RoamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Status: Off'), findsOneWidget);
      expect(find.text('Roam Mode'), findsOneWidget);
      expect(find.text("Spend like a local when you're away."), findsOneWidget);
      expect(find.text('Land. Connect. Spend.'), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('Kenya'), findsOneWidget);
      expect(find.text('Ghana'), findsOneWidget);
      expect(find.text('Rwanda'), findsOneWidget);
      expect(find.text('Uganda'), findsOneWidget);
      expect(find.text('Tanzania'), findsOneWidget);
      expect(find.text('South Africa'), findsOneWidget);
    });

    // 10. Roam Activation: Confirmation modal & exact copy
    testWidgets(
        '10. Roam activation confirmation modal displays exact adaptation copy',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketProvider.overrideWith((ref) => MarketNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const RoamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Kenya destination
      await tester.tap(find.text('Kenya'));
      await tester.pumpAndSettle();

      // Verify confirmation sheet
      expect(find.text('Activate Roam in Kenya?'), findsOneWidget);
      expect(find.text('Hanbova will adapt:'), findsOneWidget);
      expect(find.text('• Local currency'), findsOneWidget);
      expect(find.text('• Local payment options'), findsOneWidget);
      expect(find.text('• eSIM packages'), findsOneWidget);
      expect(find.text('• Bills and services'), findsOneWidget);
      expect(find.text('Your country of residence remains Nigeria.'),
          findsOneWidget);
      expect(find.text('Activate Roam'), findsOneWidget);
    });

    // 11. Roam Activation Model: Switches spend country to KE and currency to KES while preserving NG residence
    test(
        '11. Roam activation model switches active market and preserves residence',
        () async {
      final notifier = MarketNotifier();
      expect(notifier.state.residenceCountry, 'NG');
      expect(notifier.state.activeMarket, 'NG');
      expect(notifier.state.isRoamActive, isFalse);
      expect(notifier.state.displayCurrency, FiatCurrency.ngn);

      // Activate Kenya
      await notifier.activateRoam('KE');
      expect(notifier.state.residenceCountry, 'NG'); // Preserved!
      expect(notifier.state.activeMarket, 'KE');
      expect(notifier.state.isRoamActive, isTrue);
      expect(notifier.state.displayCurrency, FiatCurrency.kes);

      // Deactivate
      await notifier.deactivateRoam();
      expect(notifier.state.residenceCountry, 'NG'); // Preserved!
      expect(notifier.state.activeMarket, 'NG');
      expect(notifier.state.isRoamActive, isFalse);
      expect(notifier.state.displayCurrency, FiatCurrency.ngn);
    });

    // 12. Active Roam Screen: Exact labels and Turn Off Roam button
    testWidgets(
        '12. Active Roam screen displays Roam Active, Residence, Current market, and Turn Off Roam',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final notifier = MarketNotifier();
      await notifier.activateRoam('KE');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const RoamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Roam Active'), findsOneWidget);
      expect(find.text('Residence'), findsOneWidget);
      expect(find.text('Current market'), findsOneWidget);
      expect(find.text('Display currency'), findsOneWidget);
      expect(find.text('KES'), findsOneWidget);
      expect(find.text('Turn Off Roam'), findsOneWidget);
    });

    // 13. Active Roam Home indicator badge
    testWidgets(
        '13. Compact Home indicator is shown when Roam is active and hidden when off',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final notifier = MarketNotifier();

      // 13a. Off state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => notifier),
            profileProvider.overrideWith((ref) => ProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Roam active • Kenya'), findsNothing);

      // 13b. Activate Roam
      await notifier.activateRoam('KE');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWith((ref) => DemoModeNotifier()),
            marketProvider.overrideWith((ref) => notifier),
            profileProvider.overrideWith((ref) => ProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Roam active • Kenya'), findsOneWidget);
    });

    // 14. Zero state resilience: Missing profile details and initial avatar
    test('14. Profile model provides clean initials and zero-state resilience',
        () {
      const defaultProfile = UserProfileData();
      expect(defaultProfile.initials, 'JJ');
      expect(defaultProfile.handle, '@jaykon');

      const customProfile = UserProfileData(
        firstName: 'Alice',
        lastName: 'Smith',
        username: 'alice',
      );
      expect(customProfile.initials, 'AS');
      expect(customProfile.handle, '@alice');

      const singleNameProfile = UserProfileData(
        firstName: 'Solo',
        lastName: '',
      );
      expect(singleNameProfile.initials, 'SO');
    });
  });
}
