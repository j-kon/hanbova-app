import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/wallet_setup_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/developer_options_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/protected/presentation/protected_screen.dart';
import '../features/protected_send/presentation/claim_payment_screen.dart';
import '../features/protected_send/presentation/protected_send_screen.dart';
import '../features/receive/presentation/receive_screen.dart';
import '../features/scan/screens/scan_screen.dart';
import '../features/send/presentation/send_screen.dart';
import '../features/transactions/domain/transaction_model.dart';
import '../features/transactions/presentation/transaction_details_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'shell/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorHomeKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorActivityKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorProtectedKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorMeKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final location = state.uri.path;

      final isAuthRoute = location == '/welcome' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/reset-password' ||
          location == '/wallet-setup';

      // If unauthenticated and not on auth page, redirect to welcome
      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/welcome';
      }

      // If authenticated and on welcome or login, redirect to home
      if (isAuth && (location == '/welcome' || location == '/login' || location == '/signup')) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SignInScreen(),
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
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Activity
          StatefulShellBranch(
            navigatorKey: _shellNavigatorActivityKey,
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // Branch 2: Protected
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProtectedKey,
            routes: [
              GoRoute(
                path: '/protected',
                builder: (context, state) => const ProtectedScreen(),
              ),
            ],
          ),
          // Branch 3: Me
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMeKey,
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
          return SendScreen(initialInvoice: invoice, initialRecipient: recipient);
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
    ],
  );
});
