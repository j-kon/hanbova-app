import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/wallet_setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/mints/presentation/mints_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/developer_options_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/protected/presentation/protected_screen.dart';
import '../features/protected_send/presentation/claim_payment_screen.dart';
import '../features/protected_send/presentation/protected_send_screen.dart';
import '../features/receive/presentation/receive_screen.dart';
import '../features/scan/screens/scan_screen.dart';
import '../features/security/presentation/backup_seed_screen.dart';
import '../features/security/presentation/restore_seed_screen.dart';
import '../features/send/presentation/send_screen.dart';
import '../features/transactions/domain/transaction_model.dart';
import '../features/transactions/presentation/transaction_details_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'shell/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

String safePostLoginPath(Uri uri) =>
    uri.queryParameters['next'] == '/restore-seed' ? '/restore-seed' : '/home';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final location = state.uri.path;

      final isAuthRoute = location == '/splash' ||
          location == '/welcome' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/reset-password' ||
          location == '/wallet-setup';

      // If unauthenticated and not on auth page, redirect to welcome
      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/welcome';
      }

      if (isAuth && location == '/login') {
        return safePostLoginPath(state.uri);
      }

      // If authenticated and on another entry page, redirect to home.
      if (isAuth && (location == '/welcome' || location == '/signup')) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash & Auth routes
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) {
          final slide =
              int.tryParse(state.uri.queryParameters['slide'] ?? '0') ?? 0;
          return WelcomeScreen(
              key: ValueKey('welcome_$slide'), initialSlide: slide);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => SignInScreen(
          postLoginPath: safePostLoginPath(state.uri),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: '/wallet-setup',
        builder: (context, state) => const WalletSetupScreen(),
      ),

      // Main Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // Branch 2: Protected
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/protected',
                builder: (context, state) => const ProtectedScreen(),
              ),
            ],
          ),
          // Branch 3: Me
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Modal & Feature routes
      GoRoute(
        path: '/activity/details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tx = state.extra as TransactionModel;
          return TransactionDetailsScreen(tx: tx);
        },
      ),
      GoRoute(
        path: '/send',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final invoice = state.uri.queryParameters['invoice'];
          final recipient = state.uri.queryParameters['recipient'];
          return SendScreen(
              initialInvoice: invoice, initialRecipient: recipient);
        },
      ),
      GoRoute(
        path: '/receive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReceiveScreen(),
      ),
      GoRoute(
        path: '/protected-send',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProtectedSendScreen(),
      ),
      GoRoute(
        path: '/claim',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return ClaimPaymentScreen(initialCode: code);
        },
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/developer-options',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeveloperOptionsScreen(),
      ),
      GoRoute(
        path: '/backup-seed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupSeedScreen(),
      ),
      GoRoute(
        path: '/restore-seed',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RestoreSeedScreen(),
      ),
      GoRoute(
        path: '/mints',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MintsScreen(),
      ),
    ],
  );
});
