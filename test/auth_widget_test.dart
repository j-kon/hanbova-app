import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/auth/screens/forgot_password_screen.dart';
import 'package:hanbova_app/features/auth/screens/sign_in_screen.dart';
import 'package:hanbova_app/features/auth/screens/sign_up_screen.dart';
import 'package:hanbova_app/features/auth/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

void main() {
  group('Auth Screens Widget Tests', () {
    testWidgets('WelcomeScreen renders brand tagline and actions', (tester) async {
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

    testWidgets('SignInScreen renders email/username, password and forgot password', (tester) async {
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

    testWidgets('SignUpScreen renders fields and validates input', (tester) async {
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
      expect(find.text('Email address'), findsOneWidget);

      final button = find.widgetWithText(ElevatedButton, 'Create account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders email field and continue action', (tester) async {
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
  });
}
