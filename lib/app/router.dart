import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/wallet_setup_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/beneficiaries/presentation/beneficiaries_screen.dart';
import '../features/cards/presentation/cards_screen.dart';
import '../features/conversion/presentation/conversion_flow_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/mints/presentation/mints_screen.dart';
import '../features/money/presentation/bitcoin_detail_screen.dart';
import '../features/money/presentation/money_screen.dart';
import '../features/money/presentation/stablecoin_detail_screen.dart';
import '../features/wallet/domain/asset_model.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/pending/presentation/pending_centre_screen.dart';
import '../features/profile/screens/developer_options_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/protected/presentation/protected_screen.dart';
import '../features/protected_send/presentation/claim_payment_screen.dart';
import '../features/protected_send/presentation/protected_send_screen.dart';
import '../features/receive/presentation/receive_screen.dart';
import '../features/request_money/presentation/request_money_screen.dart';
import '../features/scan/screens/scan_screen.dart';
import '../features/security/presentation/backup_seed_screen.dart';
import '../features/security/presentation/restore_seed_screen.dart';
import '../features/send/presentation/send_screen.dart';
import '../features/spend/presentation/saved_payments_screen.dart';
import '../features/spend/presentation/spend_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/statements/presentation/statements_screen.dart';
import '../features/transactions/domain/transaction_model.dart';
import '../features/transactions/presentation/transaction_details_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/travel/presentation/esim_screen.dart';
import '../features/roam/presentation/roam_screen.dart';
import 'shell/app_shell.dart';

import '../features/spend/presentation/airtime_flow_screen.dart';
import '../features/spend/presentation/data_bundle_flow_screen.dart';
import '../features/spend/presentation/electricity_flow_screen.dart';
import '../features/spend/presentation/internet_flow_screen.dart';
import '../features/spend/presentation/pay_hub_screen.dart';
import '../features/spend/presentation/tv_subscription_flow_screen.dart';
import '../features/spend/presentation/water_flow_screen.dart';

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

      if (location == '/developer-options' && !kDebugMode) {
        return '/settings';
      }

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

      // Main Navigation Shell (5 Standard Tabs: Home, Pay, Activity, Travel, Me)
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
          // Branch 1: Pay Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pay',
                builder: (context, state) => const PayHubScreen(),
              ),
            ],
          ),
          // Branch 2: Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // Branch 3: Money (Balances, Protected, Pending, Insights, Statements)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                builder: (context, state) => const MoneyScreen(),
              ),
            ],
          ),
          // Branch 4: Profile (Identity, Account, Preferences, Settings)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Modal & Feature routes
      GoRoute(
        path: '/pay/airtime',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AirtimeFlowScreen(),
      ),
      GoRoute(
        path: '/pay/data',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DataBundleFlowScreen(),
      ),
      GoRoute(
        path: '/pay/electricity',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ElectricityFlowScreen(),
      ),
      GoRoute(
        path: '/pay/tv',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TvSubscriptionFlowScreen(),
      ),
      GoRoute(
        path: '/pay/internet',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InternetFlowScreen(),
      ),
      GoRoute(
        path: '/pay/water',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WaterFlowScreen(),
      ),
      GoRoute(
        path: '/protected',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProtectedScreen(),
      ),

      // Modal & Feature routes
      GoRoute(
        path: '/me',
        redirect: (context, state) => '/profile',
      ),
      GoRoute(
        path: '/insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/pending',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PendingCentreScreen(),
      ),
      GoRoute(
        path: '/statements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatementsScreen(),
      ),
      GoRoute(
        path: '/beneficiaries',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BeneficiariesScreen(),
      ),
      GoRoute(
        path: '/request-money',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RequestMoneyScreen(),
      ),
      GoRoute(
        path: '/saved-payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavedPaymentsScreen(),
      ),
      GoRoute(
        path: '/cards',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CardsScreen(),
      ),
      GoRoute(
        path: '/activity/details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tx = state.extra as TransactionModel;
          return TransactionDetailsScreen(transaction: tx);
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
        path: '/convert',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConversionFlowScreen(),
      ),
      GoRoute(
        path: '/money/bitcoin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BitcoinDetailScreen(),
      ),
      GoRoute(
        path: '/money/usdt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const StablecoinDetailScreen(asset: AssetType.usdt),
      ),
      GoRoute(
        path: '/money/usdc',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const StablecoinDetailScreen(asset: AssetType.usdc),
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
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/roam',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoamScreen(),
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
      GoRoute(
        path: '/travel',
        redirect: (context, state) => '/roam',
      ),
      GoRoute(
        path: '/esim',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EsimScreen(),
      ),
      GoRoute(
        path: '/spend',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SpendScreen(),
      ),
    ],
  );
});
