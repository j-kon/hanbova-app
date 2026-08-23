import 'package:flutter/material.dart';

class AppColors {
  // Brand Accents
  static const Color primaryGreen = Color(0xFF00D18F);
  static const Color primaryGreenDark = Color(0xFF00A873);
  static const Color secondaryTeal = Color(0xFF00B4D8);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color protectedBlue = Color(0xFF3A86FF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Flow directions
  static const Color incoming = Color(0xFF10B981);
  static const Color outgoing = Color(0xFFF43F5E);
  static const Color protected = Color(0xFF3A86FF);

  // Dark Theme Palette (Default / Calm Fintech)
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF151C28);
  static const Color darkSurfaceElevated = Color(0xFF1E2838);
  static const Color darkSurfaceCard = Color(0xFF161F2E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF263346);

  // Light Theme Palette (Calm, Premium, High Contrast)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
}

class HanbovaColors extends ThemeExtension<HanbovaColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceCard;
  final Color primary;
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
    primary: AppColors.primaryGreen,
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
    primary: AppColors.primaryGreenDark,
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
  HanbovaColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceCard,
    Color? primary,
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
  HanbovaColors lerp(ThemeExtension<HanbovaColors>? other, double t) {
    if (other is! HanbovaColors) return this;
    return HanbovaColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
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

extension ThemeExtensionContext on BuildContext {
  HanbovaColors get colors => Theme.of(this).extension<HanbovaColors>() ?? HanbovaColors.dark;
}
