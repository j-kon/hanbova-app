import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'support/memory_transaction_ledger.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'phone navigation and ${dark ? 'dark' : 'light'} screen rendering',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fonts = FontLoader('Poppins')
        ..addFont(rootBundle.load('assets/fonts/poppins/Poppins-Regular.ttf'));
      await fonts.load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      final demo = DemoModeNotifier();
      addTearDown(demo.dispose);
      final transactions = await createMemoryTransactionsNotifier(
          initial: demo.state.demoTransactions);
      final router = GoRouter(initialLocation: '/home', routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            for (final entry in <String, Widget>{
              '/home': const HomeScreen(),
              '/pay': const Scaffold(),
              '/activity': const TransactionsScreen(),
              '/money': const MoneyScreen(),
              '/profile': const Scaffold(),
            }.entries)
              StatefulShellBranch(routes: [
                GoRoute(path: entry.key, builder: (_, __) => entry.value)
              ]),
          ],
        ),
      ]);
      addTearDown(router.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            transactionsProvider.overrideWith((ref) => transactions),
          ],
          child: RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                routerConfig: router,
              ))));
      await tester.pumpAndSettle();
      for (final screen in ['Home', 'Money', 'Activity']) {
        await tester.tap(find.text(screen).last);
        await tester.pumpAndSettle();
        final navigation =
            tester.getRect(find.byKey(const Key('main-navigation')));
        final content = tester.getRect(find.byType(StatefulNavigationShell));
        expect(content.bottom, lessThanOrEqualTo(navigation.top),
            reason: 'Navigation must not cover content');
        if (const bool.fromEnvironment('CAPTURE_PRODUCT_SCREENS')) {
          await tester.runAsync(() async {
            final boundary = boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final screenshot = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await screenshot.toByteData(format: ui.ImageByteFormat.png);
            await File(
                    '/tmp/hanbova-${screen.toLowerCase()}-${dark ? 'dark' : 'light'}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            screenshot.dispose();
          });
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
