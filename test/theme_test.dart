import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/core/theme/theme_controller.dart';

void main() {
  group('Theme Engine Tests', () {
    test('Dark theme contains valid HanbovaColors extension', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      final colors = theme.extension<HanbovaColors>();
      expect(colors, isNotNull);
      expect(colors!.primary, AppColors.primaryGreen);
      expect(colors.protected, AppColors.protected);
    });

    test('Light theme contains valid HanbovaColors extension', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      final colors = theme.extension<HanbovaColors>();
      expect(colors, isNotNull);
      expect(colors!.primary, AppColors.primaryGreenDark);
      expect(colors.protected, AppColors.protected);
    });

    test('ThemeController updates state correctly', () async {
      final controller = ThemeController();
      expect(controller.state, ThemeMode.system);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.state, ThemeMode.dark);

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.state, ThemeMode.light);
    });
  });
}
