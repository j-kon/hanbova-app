import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/crypto/crypto_identity_service.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';
import 'package:hanbova_app/features/auth/screens/forgot_password_screen.dart';
import 'package:hanbova_app/features/auth/screens/sign_in_screen.dart';
import 'package:hanbova_app/features/auth/screens/sign_up_screen.dart';
import 'package:hanbova_app/features/auth/screens/wallet_setup_screen.dart';
import 'package:hanbova_app/features/auth/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCryptoIdentityNotifier extends CryptoIdentityNotifier {
  final WalletCryptoIdentity _mockIdentity;
  MockCryptoIdentityNotifier(this._mockIdentity);

  @override
  Future<WalletCryptoIdentity?> build() async => _mockIdentity;

  @override
  Future<WalletCryptoIdentity> getOrCreateIdentity() async {
    return _mockIdentity;
  }

  @override
  Future<void> publishPublicKeys({
    required ApiClient apiClient,
    required WalletCryptoIdentity identity,
    String? walletEnvironment,
  }) async {}
}

class MockCashuWalletService implements CashuWalletService {
  final CashuWalletBalance balance;
  final bool shouldThrowOnGetBalance;

  MockCashuWalletService({
    this.balance =
        const CashuWalletBalance(spendableSats: 1000, lockedEscrowSats: 0),
    this.shouldThrowOnGetBalance = false,
  });

  @override
  Future<CashuWalletBalance> getBalance() async {
    if (shouldThrowOnGetBalance) {
      throw StateError('Simulated CDK Redb initialization failure');
    }
    return balance;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Auth Screens Widget Tests', () {
    testWidgets('WelcomeScreen renders brand tagline and actions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(),
        ),
      );

      expect(find.text('Hanbova'), findsOneWidget);
      expect(find.text('Send protected.'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
        'SignInScreen renders email/username, password and forgot password',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(child: SignInScreen()),
        ),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email or username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('SignUpScreen renders fields and validates input',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(child: SignUpScreen()),
        ),
      );

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Last name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);

      final button = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders email field and continue action',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(child: ForgotPasswordScreen()),
        ),
      );

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
        'WalletSetupScreen renders step 1 backup phrase when CDK wallet succeeds',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUser = UserProfile(
        id: 'test_user_id',
        username: 'alice',
        handle: '@alice',
        email: 'alice@hanbova.test',
        firstName: 'Alice',
        lastName: 'Test',
        displayName: 'Alice Test',
        emailVerified: true,
        createdAt: DateTime.now(),
      );

      final mockKeyPair = await X25519().newKeyPair();
      final mockIdentity = WalletCryptoIdentity(
        context: const WalletContextKey(
          userId: 'test_user_id',
          network: HanbovaNetwork.local,
          storagePrefix: 'wallet_local',
        ),
        protectedPaymentPubkey:
            '02abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportEncryptionPubkey:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportKeyPair: mockKeyPair,
        protectedPaymentPrivkeyHex:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        walletSeedHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
      );

      final mockHttpClient = MockClient((request) async {
        return http.Response('{"success": true}', 200,
            headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  AuthState.authenticated(mockUser, 'mock_jwt_token'),
                ),
              ),
              cryptoIdentityProvider
                  .overrideWith(() => MockCryptoIdentityNotifier(mockIdentity)),
              cashuWalletServiceProvider
                  .overrideWithValue(MockCashuWalletService()),
              apiClientProvider.overrideWithValue(
                ApiClient(
                    baseUrl: 'https://mock.api', httpClient: mockHttpClient),
              ),
            ],
            child: const WalletSetupScreen(),
          ),
        ),
      );

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Write Down Your Recovery Phrase'), findsOneWidget);
      expect(
          find.text(
              'Write these words down and keep them private. Never share them with anyone.'),
          findsOneWidget);
      expect(find.text('I Have Written It Down'), findsOneWidget);
    });

    testWidgets(
        'WalletSetupScreen blocks onboarding if cashuWalletServiceProvider is null',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUser = UserProfile(
        id: 'test_user_id',
        username: 'alice',
        handle: '@alice',
        email: 'alice@hanbova.test',
        firstName: 'Alice',
        lastName: 'Test',
        displayName: 'Alice Test',
        emailVerified: true,
        createdAt: DateTime.now(),
      );

      final mockKeyPair = await X25519().newKeyPair();
      final mockIdentity = WalletCryptoIdentity(
        context: const WalletContextKey(
          userId: 'test_user_id',
          network: HanbovaNetwork.local,
          storagePrefix: 'wallet_local',
        ),
        protectedPaymentPubkey:
            '02abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportEncryptionPubkey:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportKeyPair: mockKeyPair,
        protectedPaymentPrivkeyHex:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        walletSeedHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
      );

      final mockHttpClient = MockClient((request) async {
        return http.Response('{"success": true}', 200,
            headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  AuthState.authenticated(mockUser, 'mock_jwt_token'),
                ),
              ),
              cryptoIdentityProvider
                  .overrideWith(() => MockCryptoIdentityNotifier(mockIdentity)),
              cashuWalletServiceProvider.overrideWithValue(null),
              apiClientProvider.overrideWithValue(
                ApiClient(
                    baseUrl: 'https://mock.api', httpClient: mockHttpClient),
              ),
            ],
            child: const WalletSetupScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must show Initialization Failed and NOT show step 1 backup phrase
      expect(find.text('Initialization Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Write Down Your Recovery Phrase'), findsNothing);
    });

    testWidgets(
        'WalletSetupScreen blocks onboarding if wallet.getBalance throws',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUser = UserProfile(
        id: 'test_user_id',
        username: 'alice',
        handle: '@alice',
        email: 'alice@hanbova.test',
        firstName: 'Alice',
        lastName: 'Test',
        displayName: 'Alice Test',
        emailVerified: true,
        createdAt: DateTime.now(),
      );

      final mockKeyPair = await X25519().newKeyPair();
      final mockIdentity = WalletCryptoIdentity(
        context: const WalletContextKey(
          userId: 'test_user_id',
          network: HanbovaNetwork.local,
          storagePrefix: 'wallet_local',
        ),
        protectedPaymentPubkey:
            '02abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportEncryptionPubkey:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        transportKeyPair: mockKeyPair,
        protectedPaymentPrivkeyHex:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        walletSeedHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
      );

      final mockHttpClient = MockClient((request) async {
        return http.Response('{"success": true}', 200,
            headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  AuthState.authenticated(mockUser, 'mock_jwt_token'),
                ),
              ),
              cryptoIdentityProvider
                  .overrideWith(() => MockCryptoIdentityNotifier(mockIdentity)),
              cashuWalletServiceProvider.overrideWithValue(
                MockCashuWalletService(shouldThrowOnGetBalance: true),
              ),
              apiClientProvider.overrideWithValue(
                ApiClient(
                    baseUrl: 'https://mock.api', httpClient: mockHttpClient),
              ),
            ],
            child: const WalletSetupScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must show Initialization Failed and NOT show step 1 backup phrase
      expect(find.text('Initialization Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Write Down Your Recovery Phrase'), findsNothing);
    });

    testWidgets('WalletSetupScreen fails closed if user is unauthenticated',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  AuthState.unauthenticated(),
                ),
              ),
            ],
            child: const WalletSetupScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.text('Sign In to Continue'), findsOneWidget);
    });
  });
}
