import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/theme/hanbova_brand_tokens.dart';
import 'package:hanbova_app/features/auth/screens/welcome_screen.dart';
import 'package:hanbova_app/features/splash/presentation/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hanbova Brand V4 Tokens & Theme Tests', () {
    test('Official Brand V4 Color Tokens match specification', () {
      expect(HanbovaBrandV4.bitcoinOrange.toARGB32(), 0xFFF7931A);
      expect(HanbovaBrandV4.lightningGold.toARGB32(), 0xFFFFC400);
      expect(HanbovaBrandV4.charcoal.toARGB32(), 0xFF172027);
      expect(HanbovaBrandV4.graphite.toARGB32(), 0xFF25323A);
      expect(HanbovaBrandV4.warmWhite.toARGB32(), 0xFFFAFAF7);
      expect(HanbovaBrandV4.softGray.toARGB32(), 0xFF6E7A80);
      expect(HanbovaBrandV4.success.toARGB32(), 0xFF2E8B57);
      expect(HanbovaBrandV4.warning.toARGB32(), 0xFFD98B00);
      expect(HanbovaBrandV4.danger.toARGB32(), 0xFFC44747);
      expect(HanbovaBrandV4.info.toARGB32(), 0xFF3B82F6);
    });

    test('Dark theme configures Brand V4 palette', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(darkTheme.colorScheme.primary, AppColors.bitcoinOrange);
      expect(darkTheme.colorScheme.secondary, AppColors.lightningGold);
      expect(darkTheme.colorScheme.surface, AppColors.darkSurface);

      final colors = darkTheme.extension<HanbovaColors>()!;
      expect(colors.background, AppColors.charcoal);
      expect(colors.surface, AppColors.graphite);
      expect(colors.primary, AppColors.bitcoinOrange);
      expect(colors.gold, AppColors.lightningGold);
      expect(colors.textPrimary, AppColors.warmWhite);
    });

    test('Light theme configures Brand V4 palette', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(lightTheme.colorScheme.primary, AppColors.bitcoinOrange);
      expect(lightTheme.colorScheme.secondary, AppColors.lightningGold);

      final colors = lightTheme.extension<HanbovaColors>()!;
      expect(colors.background, AppColors.warmWhite);
      expect(colors.primary, AppColors.bitcoinOrange);
      expect(colors.gold, AppColors.lightningGold);
      expect(colors.textPrimary, AppColors.charcoal);
    });

    testWidgets('SplashScreen renders Brand V4 elements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          ),
        ),
      );

      expect(find.text('Hanbova'), findsOneWidget);
      expect(find.text('Send protected.'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('WelcomeScreen renders all 3 Brand V4 slides', (tester) async {
      // Slide 1
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(initialSlide: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Send instantly.'), findsOneWidget);
      expect(find.text('Fast everyday Bitcoin payments for people you trust.'),
          findsOneWidget);

      // Slide 2
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(initialSlide: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('title_1')), findsOneWidget);
      expect(
          find.text(
              'Use a protected Cashu payment when you want a sender refund path after a chosen locktime.'),
          findsOneWidget);

      // Slide 3
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(initialSlide: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Built for everyday commerce.'), findsOneWidget);
      expect(
          find.text(
              'A mobile-first experience designed around real person-to-person payment situations.'),
          findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
