import 'package:flutter/material.dart';
import 'hanbova_brand_tokens.dart';

class AppColors {
  // Master Brand V4 Tokens
  static const Color bitcoinOrange = HanbovaBrandV4.bitcoinOrange;
  static const Color lightningGold = HanbovaBrandV4.lightningGold;
  static const Color charcoal = HanbovaBrandV4.charcoal;
  static const Color graphite = HanbovaBrandV4.graphite;
  static const Color warmWhite = HanbovaBrandV4.warmWhite;
  static const Color softGray = HanbovaBrandV4.softGray;
  static const Color orangeDeep = HanbovaBrandV4.orangeDeep;
  static const Color orangeLight = HanbovaBrandV4.orangeLight;
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Status & Semantic Tokens
  static const Color success = HanbovaBrandV4.success;
  static const Color warning = HanbovaBrandV4.warning;
  static const Color danger = HanbovaBrandV4.danger;
  static const Color info = HanbovaBrandV4.info;
  static const Color pending = HanbovaBrandV4.warning;
  static const Color error = HanbovaBrandV4.danger;

  // Primary & Accent Aliases
  static const Color primary = bitcoinOrange;
  static const Color primaryDark = orangeDeep;
  static const Color accentGold = lightningGold;
  static const Color protected = bitcoinOrange;

  // Flow directions
  static const Color incoming = success;
  static const Color outgoing = danger;

  // Dark Theme Palette (Charcoal Lead)
  static const Color darkBackground = charcoal;
  static const Color darkSurface = graphite;
  static const Color darkSurfaceElevated = Color(0xFF2D3B44);
  static const Color darkSurfaceCard = graphite;
  static const Color darkCardBackground = graphite;
  static const Color darkTextPrimary = warmWhite;
  static const Color darkTextSecondary = Color(0xFF9AA6AC);
  static const Color darkTextTertiary = softGray;
  static const Color darkDivider = Color(0xFF2D3B44);
  static const Color darkBorder = Color(0xFF33434E);

  // Light Theme Palette (Warm White Lead)
  static const Color lightBackground = warmWhite;
  static const Color lightSurface = pureWhite;
  static const Color lightSurfaceElevated = Color(0xFFF2F2ED);
  static const Color lightSurfaceCard = pureWhite;
  static const Color lightTextPrimary = charcoal;
  static const Color lightTextSecondary = softGray;
  static const Color lightTextTertiary = Color(0xFF8A969C);
  static const Color lightDivider = Color(0xFFE8E8E1);
  static const Color lightBorder = Color(0xFFDEDFD7);
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
    primary: AppColors.bitcoinOrange,
    primaryDark: AppColors.orangeDeep,
    gold: AppColors.lightningGold,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    divider: AppColors.darkDivider,
    border: AppColors.darkBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    protected: AppColors.protected,
    incoming: AppColors.incoming,
    outgoing: AppColors.outgoing,
  );

  static const light = HanbovaColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceCard: AppColors.lightSurfaceCard,
    primary: AppColors.bitcoinOrange,
    primaryDark: AppColors.orangeDeep,
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
