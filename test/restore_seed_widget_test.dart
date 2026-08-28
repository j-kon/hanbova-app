import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/app/router.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/screens/sign_in_screen.dart';
import 'package:hanbova_app/features/auth/screens/welcome_screen.dart';
import 'package:hanbova_app/features/security/application/restore_wallet_controller.dart';
import 'package:hanbova_app/features/security/presentation/restore_seed_screen.dart';

const validMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

const aliceContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

final class RestoreCallRecorder {
  int restoreCalls = 0;
}

final class RecordingRestoreController extends RestoreWalletController {
  final RestoreCallRecorder recorder;

  RecordingRestoreController(super.ref, this.recorder);

  @override
  Future<RestoreWalletResult> restore(String mnemonic) async {
    recorder.restoreCalls += 1;
    throw StateError('A cancelled confirmation must not invoke restore.');
  }
}

Future<RestoreCallRecorder> pumpRestoreScreen(
  WidgetTester tester, {
  required WalletContextKey? activeContext,
}) async {
  final recorder = RestoreCallRecorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeWalletContextKeyProvider.overrideWithValue(activeContext),
        restoreWalletControllerProvider.overrideWith(
          (ref) => RecordingRestoreController(ref, recorder),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const RestoreSeedScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return recorder;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('post-login destination permits only the restore route', () {
    expect(
      safePostLoginPath(Uri.parse('/login?next=%2Frestore-seed')),
      '/restore-seed',
    );
    expect(safePostLoginPath(Uri.parse('/login?next=%2Fsend')), '/home');
    expect(
        safePostLoginPath(Uri.parse('/login?next=https://evil.test')), '/home');
    expect(safePostLoginPath(Uri.parse('/login')), '/home');
  });

  testWidgets('welcome restore action sends the user through sign in',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(initialSlide: 2),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const SignInScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final restoreAction =
        find.widgetWithText(TextButton, 'Sign in to restore with phrase');
    await tester.ensureVisible(restoreAction);
    await tester.tap(restoreAction);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    final loginUri =
        GoRouterState.of(tester.element(find.byType(SignInScreen))).uri;
    expect(loginUri.path, '/login');
    expect(loginUri.queryParameters['next'], '/restore-seed');
  });

  testWidgets('restore form is absent without an authenticated context',
      (tester) async {
    await pumpRestoreScreen(tester, activeContext: null);

    expect(find.text('Sign in to restore your wallet'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('restore requires explicit replacement confirmation',
      (tester) async {
    final recorder =
        await pumpRestoreScreen(tester, activeContext: aliceContext);
    final words = validMnemonic.split(' ');
    for (var i = 0; i < words.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), words[i]);
    }

    await tester.ensureVisible(find.text('Restore Wallet'));
    await tester.tap(find.text('Restore Wallet'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This replaces the wallet identity for the signed-in account in this wallet environment.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(recorder.restoreCalls, 0);
  });
}
