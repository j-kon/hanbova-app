import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../domain/instant_send_controller.dart';

class InstantSendReviewCard extends StatelessWidget {
  const InstantSendReviewCard({super.key, required this.review});

  final InstantSendQuote review;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Lightning payment',
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewRow(
            label: 'Invoice amount',
            value: Formatters.formatSats(review.amountSats),
          ),
          _ReviewRow(
            label: 'Maximum fee',
            value: Formatters.formatSats(review.feeReserveSats),
          ),
          const Divider(),
          _ReviewRow(
            label: 'Maximum total',
            value: Formatters.formatSats(review.totalSats),
            emphasize: true,
          ),
          _ReviewRow(label: 'Network', value: review.networkLabel),
          _ReviewRow(
            label: 'Invoice fingerprint',
            value: review.invoiceFingerprint,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lightning payments are final. Confirm only if the amount, network, and invoice fingerprint are correct.',
            style: AppTypography.bodySmall.copyWith(color: colors.warning),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style:
                (emphasize ? AppTypography.titleSmall : AppTypography.bodySmall)
                    .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
