import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/router.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Sign Out and Auth Route Redirection Tests', () {
    testWidgets(
        'Tapping Sign Out on ProfileScreen logs out and navigates to /welcome',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      var navigatedLocation = '';

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/welcome',
            builder: (context, state) {
              navigatedLocation = '/welcome';
              return const Scaffold(body: Text('WELCOME_SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile is rendered
      expect(find.text('Profile'), findsOneWidget);

      // Scroll to find Sign Out tile
      final signOutFinder = find.text('Sign Out');
      await tester.scrollUntilVisible(signOutFinder, 200);
      expect(signOutFinder, findsOneWidget);

      // Tap Sign Out tile
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Sign Out?'), findsOneWidget);
      expect(
        find.text(
            'Make sure your wallet recovery seed is safely backed up before signing out.'),
        findsOneWidget,
      );

      // Tap Sign Out inside the dialog
      final dialogSignOutFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sign Out'),
      );
      await tester.tap(dialogSignOutFinder);
      await tester.pumpAndSettle();

      // Verify navigation to /welcome occurred without GoException
      expect(find.text('WELCOME_SCREEN'), findsOneWidget);
      expect(navigatedLocation, '/welcome');
    });

    testWidgets(
        'App router cleanly handles /auth/welcome by redirecting to /welcome',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: _TestRouterApp(initialLocation: '/auth/welcome'),
        ),
      );
      await tester.pumpAndSettle();

      // WelcomeScreen should be rendered without any GoException
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Page Not Found'), findsNothing);
      expect(find.textContaining('GoException'), findsNothing);
    });

    testWidgets(
        'App router cleanly handles /auth/login and /auth/signup redirects',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: _TestRouterApp(initialLocation: '/auth/login'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page Not Found'), findsNothing);
      expect(find.textContaining('GoException'), findsNothing);

      await tester.pumpWidget(
        const ProviderScope(
          child: _TestRouterApp(initialLocation: '/auth/signup'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page Not Found'), findsNothing);
      expect(find.textContaining('GoException'), findsNothing);
    });
  });
}

class _TestRouterApp extends ConsumerWidget {
  final String initialLocation;
  const _TestRouterApp({required this.initialLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(initialLocation);
    });
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
