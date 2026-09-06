import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// The spendable amount is primary; unsettled funds stay visually separate.
class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard(
      {super.key,
      required this.amount,
      required this.sats,
      required this.protectedAmount,
      required this.pendingAmount,
      required this.environmentLabel,
      required this.isHidden,
      required this.onToggleVisibility,
      required this.onProtected,
      required this.onPending,
      this.onEnvironment,
      this.isLoading = false,
      this.hasError = false,
      this.onRetry,
      this.title = 'Bitcoin',
      this.showMotion = true});

  final String amount, sats, protectedAmount, pendingAmount, environmentLabel;
  final String title;
  final bool showMotion;
  final bool isHidden, isLoading, hasError;
  final VoidCallback onToggleVisibility, onProtected, onPending;
  final VoidCallback? onEnvironment, onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surfaceCard,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: AppTypography.titleSmall
                        .copyWith(color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text('Available to spend',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary)),
              ])),
          IconButton(
              tooltip: isHidden ? 'Show balances' : 'Hide balances',
              onPressed: onToggleVisibility,
              icon: Icon(
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.textSecondary)),
        ]),
        const SizedBox(height: 16),
        if (isLoading) ...[
          Text('Updating balance…',
              style: AppTypography.titleLarge
                  .copyWith(color: colors.textSecondary)),
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ] else if (hasError) ...[
          Text('Balance unavailable',
              style:
                  AppTypography.titleLarge.copyWith(color: colors.textPrimary)),
          Text('Refresh to check your available funds.',
              style: AppTypography.bodySmall
                  .copyWith(color: colors.textSecondary)),
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ] else ...[
          Text(amount,
              style: AppTypography.display.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text(sats,
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary)),
        ],
        if (environmentLabel.isNotEmpty) ...[
          const SizedBox(height: 12),
          InkWell(
              onTap: onEnvironment,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(environmentLabel,
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.textSecondary))),
                  ]))),
        ],
        if (showMotion) ...[
          Divider(height: 24, color: colors.divider),
          Text('Money in motion',
              style: AppTypography.bodySmall
                  .copyWith(color: colors.textSecondary)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final large = MediaQuery.textScalerOf(context).scale(14) > 21;
            final width =
                large ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                  width: width,
                  child: _motion(context, 'Protected', protectedAmount,
                      Icons.shield_outlined, onProtected)),
              SizedBox(
                  width: width,
                  child: _motion(context, 'Pending', pendingAmount,
                      Icons.schedule, onPending)),
            ]);
          }),
        ],
      ]),
    );
  }

  Widget _motion(BuildContext context, String title, String value,
      IconData icon, VoidCallback onTap) {
    final colors = context.colors;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 16, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(title,
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)))
              ]),
              const SizedBox(height: 6),
              Text(value,
                  style: AppTypography.titleSmall
                      .copyWith(color: colors.textPrimary)),
            ])));
  }
}
