import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';

void main() {
  testWidgets('center action exposes a labelled 48dp Pay button',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            for (final path in ['/home', '/activity', '/money', '/profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, __) => const Scaffold(body: SizedBox()),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
            routerConfig: router, theme: AppTheme.lightTheme),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('center-pay-button'));
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    final semantics = tester.getSemantics(button);
    expect(semantics.label, 'Pay');
    expect(semantics.flagsCollection.isButton, isTrue);
  });
}
