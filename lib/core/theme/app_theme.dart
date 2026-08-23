import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        onPrimary: Color(0xFF003822),
        secondary: AppColors.secondaryTeal,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      extensions: const [HanbovaColors.dark],
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: const Color(0xFF003822),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: AppTypography.titleSmall,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextTertiary),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreenDark,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryTeal,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      extensions: const [HanbovaColors.light],
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primaryGreenDark,
        unselectedItemColor: AppColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreenDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreenDark,
          textStyle: AppTypography.titleSmall,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.primaryGreenDark, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      ),
    );
  }
}
