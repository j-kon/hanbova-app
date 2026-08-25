import 'package:flutter/material.dart';

class AppColors {
  // Master Brand Tokens from brand_tokens.json
  static const Color deepForest = Color(0xFF012D1B);
  static const Color forestGreen = Color(0xFF013B23);
  static const Color ribbonGreen = Color(0xFF02482A);
  static const Color leafGreen = Color(0xFF66B33D);
  static const Color lightLeaf = Color(0xFF7BCB45);
  static const Color lightningGold = Color(0xFFFDBF09);
  static const Color warmCream = Color(0xFFF7F4EC);
  static const Color charcoal = Color(0xFF1B1F23);
  static const Color softCharcoal = Color(0xFF5C6762);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFC44747);
  static const Color pending = Color(0xFFD98B00);
  static const Color success = Color(0xFF2E8B57);

  // Aliases for semantic compatibility
  static const Color primaryGreen = leafGreen;
  static const Color primaryGreenDark = forestGreen;
  static const Color accentGold = lightningGold;
  static const Color error = danger;
  static const Color warning = pending;
  static const Color info = leafGreen;
  static const Color protectedBlue = forestGreen;

  // Flow directions
  static const Color incoming = success;
  static const Color outgoing = danger;
  static const Color protected = leafGreen;

  // Dark Theme Palette (Deep Forest Lead)
  static const Color darkBackground = deepForest;
  static const Color darkSurface = forestGreen;
  static const Color darkSurfaceElevated = ribbonGreen;
  static const Color darkSurfaceCard = forestGreen;
  static const Color darkTextPrimary = pureWhite;
  static const Color darkTextSecondary = Color(0xFFC8D8CF);
  static const Color darkTextTertiary = Color(0xFF9AB2A6);
  static const Color darkDivider = ribbonGreen;
  static const Color darkBorder = Color(0xFF084E31);

  // Light Theme Palette (Warm Cream Lead)
  static const Color lightBackground = warmCream;
  static const Color lightSurface = pureWhite;
  static const Color lightSurfaceElevated = Color(0xFFEFECE4);
  static const Color lightSurfaceCard = pureWhite;
  static const Color lightTextPrimary = charcoal;
  static const Color lightTextSecondary = Color(0xFF4A5550);
  static const Color lightTextTertiary = Color(0xFF6E7B75);
  static const Color lightDivider = Color(0xFFE5E0D5);
  static const Color lightBorder = Color(0xFFD8D2C6);
}

class HanbovaColors extends ThemeExtension<HanbovaColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceCard;
  final Color primary;
  final Color primaryDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color protected;
  final Color incoming;
  final Color outgoing;

  const HanbovaColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceCard,
    required this.primary,
    required this.primaryDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.protected,
    required this.incoming,
    required this.outgoing,
  });

  static const dark = HanbovaColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    surfaceCard: AppColors.darkSurfaceCard,
    primary: AppColors.leafGreen,
    primaryDark: AppColors.forestGreen,
    gold: AppColors.lightningGold,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    divider: AppColors.darkDivider,
    border: AppColors.darkBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    protected: AppColors.leafGreen,
    incoming: AppColors.incoming,
    outgoing: AppColors.outgoing,
  );

  static const light = HanbovaColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceCard: AppColors.lightSurfaceCard,
    primary: AppColors.forestGreen,
    primaryDark: AppColors.deepForest,
    gold: AppColors.lightningGold,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    divider: AppColors.lightDivider,
    border: AppColors.lightBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    protected: AppColors.protected,
    incoming: AppColors.incoming,
    outgoing: AppColors.outgoing,
  );

  @override
  ThemeExtension<HanbovaColors> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceCard,
    Color? primary,
    Color? primaryDark,
    Color? gold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? protected,
    Color? incoming,
    Color? outgoing,
  }) {
    return HanbovaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      protected: protected ?? this.protected,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
    );
  }

  @override
  ThemeExtension<HanbovaColors> lerp(
      covariant ThemeExtension<HanbovaColors>? other, double t) {
    if (other is! HanbovaColors) return this;
    return HanbovaColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      protected: Color.lerp(protected, other.protected, t)!,
      incoming: Color.lerp(incoming, other.incoming, t)!,
      outgoing: Color.lerp(outgoing, other.outgoing, t)!,
    );
  }
}

extension HanbovaColorsContext on BuildContext {
  HanbovaColors get colors =>
      Theme.of(this).extension<HanbovaColors>() ?? HanbovaColors.dark;
}
