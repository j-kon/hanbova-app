import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/shell/app_shell.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_send_draft.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_review.dart';

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

  testWidgets('shell destinations expose labelled 48dp tap targets',
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
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
            routerConfig: router, theme: AppTheme.lightTheme),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Activity', 'Money', 'Profile']) {
      final target = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
      final semantics = tester.getSemantics(target);
      expect(semantics.label, label);
      expect(semantics.flagsCollection.isButton, isTrue);
    }
  });

  testWidgets('protected payment review actions stay accessible at large text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ProtectedSendReview(
              draft: _protectedDraft,
              isSubmitting: false,
              onConfirm: () {},
              onEdit: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final finder in [
      find.widgetWithText(ElevatedButton, 'Confirm, Lock & Send'),
      find.widgetWithText(OutlinedButton, 'Edit payment'),
    ]) {
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      expect(tester.getSemantics(finder).flagsCollection.isButton, isTrue);
    }
  });
}

const _protectedDraft = ProtectedSendDraft(
  walletContext: WalletContextKey(
    userId: 'alice',
    network: HanbovaNetwork.cashuTest,
    storagePrefix: 'wallet_cashu_test',
  ),
  recipient: UserPaymentProfile(
    username: 'amina',
    handle: '@amina',
    walletEnvironment: 'cashu-test',
    protectedPaymentPubkey: 'protected-key',
    transportEncryptionPubkey: 'transport-key',
  ),
  amountSats: 2500,
  description: 'Invoice payment',
  expirationSeconds: 86400,
  networkLabel: 'Cashu Test',
);
