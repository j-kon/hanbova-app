import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';

void main() {
  testWidgets(
      'Bottom navigation bar has transparent background and liquid touch items',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            for (final path in [
              '/home',
              '/pay',
              '/activity',
              '/money',
              '/profile'
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, __) =>
                        Scaffold(body: Center(child: Text('Screen $path'))),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.darkTheme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify navigation bar container exists and has transparent background
    final navContainerFinder = find.byKey(const Key('main-navigation'));
    expect(navContainerFinder, findsOneWidget);

    final containerWidget = tester.widget<Container>(navContainerFinder);
    final boxDecoration = containerWidget.decoration as BoxDecoration;
    expect(boxDecoration.color, equals(Colors.transparent));

    // 2. Verify BackdropFilter is present
    final backdropFilterFinder = find.ancestor(
      of: navContainerFinder,
      matching: find.byType(BackdropFilter),
    );
    expect(backdropFilterFinder, findsOneWidget);
    final backdropWidget = tester.widget<BackdropFilter>(backdropFilterFinder);
    expect(backdropWidget.filter, isNotNull);

    // 3. Verify all 4 tabs and center action button
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(
        find.byKey(const Key('navbar_center_action_button')), findsOneWidget);

    // 4. Test liquid touch interaction on tab
    final activityTab = find.text('Activity');
    final gesture = await tester.createGesture();
    await gesture.down(tester.getCenter(activityTab));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Screen /activity'), findsOneWidget);

    // 5. Test center action button
    final centerBtn = find.byKey(const Key('navbar_center_action_button'));
    await tester.tap(centerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Pay Everyday Bills'), findsOneWidget);
  });
}
