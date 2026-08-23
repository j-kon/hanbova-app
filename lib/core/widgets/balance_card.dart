import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final int totalSats;
  final int spendableSats;
  final int protectedOutgoingSats;
  final int protectedIncomingSats;
  final String formattedFiat;
  final bool isBalanceVisible;
  final VoidCallback? onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.totalSats,
    required this.spendableSats,
    this.protectedOutgoingSats = 0,
    this.protectedIncomingSats = 0,
    required this.formattedFiat,
    this.isBalanceVisible = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border, width: 1),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              if (onToggleVisibility != null)
                IconButton(
                  icon: Icon(
                    isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleVisibility,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isBalanceVisible ? formattedFiat : '••••••••',
            style: AppTypography.display.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isBalanceVisible ? Formatters.formatSats(totalSats) : '•••• sats',
            style: AppTypography.titleSmall.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.divider),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.success, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Spendable', style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBalanceVisible ? Formatters.formatSats(spendableSats) : '••••',
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: colors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.protected, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Protected', style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBalanceVisible ? Formatters.formatSats(protectedOutgoingSats) : '••••',
                        style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
