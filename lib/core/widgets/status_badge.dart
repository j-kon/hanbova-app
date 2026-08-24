import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, bgColor, fgColor) = _getStatusConfig(status.toLowerCase(), colors, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fgColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _getStatusConfig(String status, HanbovaColors colors, bool isDark) {
    switch (status) {
      case 'claimable':
      case 'awaiting_claim':
        return (
          'Awaiting claim',
          colors.success.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.success,
        );
      case 'claimed':
      case 'succeeded':
      case 'completed':
        return (
          'Claimed',
          colors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.primary,
        );
      case 'pending':
        return (
          'Pending',
          colors.gold.withValues(alpha: isDark ? 0.18 : 0.15),
          isDark ? colors.gold : const Color(0xFFB87700),
        );
      case 'expired':
        return (
          'Expired',
          colors.textTertiary.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.textSecondary,
        );
      case 'refunded':
        return (
          'Refunded',
          colors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.primary,
        );
      case 'failed':
        return (
          'Failed',
          colors.error.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.error,
        );
      case 'created':
      default:
        return (
          status.toUpperCase(),
          colors.surfaceElevated,
          colors.textSecondary,
        );
    }
  }
}
