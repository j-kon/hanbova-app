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
  final bool isTestMode;
  final VoidCallback? onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.totalSats,
    required this.spendableSats,
    this.protectedOutgoingSats = 0,
    this.protectedIncomingSats = 0,
    required this.formattedFiat,
    this.isBalanceVisible = true,
    this.isTestMode = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final satsSuffix = isTestMode ? 'test sats' : 'sats';

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
          if (isTestMode) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: AppRadius.xsRadius,
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science_outlined,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'TEST MODE • No monetary value',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
              if (onToggleVisibility != null)
                IconButton(
                  icon: Icon(
                    isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
            isBalanceVisible
                ? '${Formatters.formatSatsNumber(totalSats)} $satsSuffix'
                : '•••• $satsSuffix',
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
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: colors.success, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Spendable',
                            style: AppTypography.bodySmall.copyWith(
                                color: colors.textTertiary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBalanceVisible
                          ? '${Formatters.formatSatsNumber(spendableSats)} $satsSuffix'
                          : '••••',
                      style: AppTypography.titleSmall
                          .copyWith(color: colors.textPrimary, fontSize: 13),
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
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: colors.protected,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Protected',
                              style: AppTypography.bodySmall.copyWith(
                                  color: colors.textTertiary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBalanceVisible
                            ? '${Formatters.formatSatsNumber(protectedOutgoingSats)} $satsSuffix'
                            : '••••',
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.textPrimary, fontSize: 13),
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
