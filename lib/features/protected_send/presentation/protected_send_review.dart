import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../domain/protected_send_draft.dart';

class ProtectedSendReview extends StatelessWidget {
  const ProtectedSendReview({
    super.key,
    required this.draft,
    required this.isSubmitting,
    required this.onConfirm,
    required this.onEdit,
    this.errorMessage,
  });

  final ProtectedSendDraft draft;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expiresAt = DateTime.now().add(
      Duration(seconds: draft.expirationSeconds),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review protected payment',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Funds are locked only after you confirm this review.',
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _ReviewRow(label: 'Recipient', value: draft.recipient.handle),
                _ReviewRow(
                  label: 'Amount',
                  value: Formatters.formatSats(draft.amountSats),
                ),
                _ReviewRow(label: 'Network', value: draft.networkLabel),
                _ReviewRow(
                  label: 'Refund available after',
                  value: Formatters.formatDate(expiresAt),
                ),
                if (draft.description.isNotEmpty)
                  _ReviewRow(label: 'Note', value: draft.description),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
            ),
            child: Text(
              'The recipient can claim while the payment remains valid. After expiry, you may request a refund, but whichever valid claim or refund reaches the mint first wins. If relay delivery fails, your locked payment remains recoverable from this device.',
              style:
                  AppTypography.bodySmall.copyWith(color: colors.textPrimary),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : onConfirm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline),
            label: const Text('Confirm, Lock & Send'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: isSubmitting ? null : onEdit,
            child: const Text('Edit payment'),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
