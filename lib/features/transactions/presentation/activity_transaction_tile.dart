import 'package:flutter/material.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../domain/transaction_model.dart';

class ActivityTransactionTile extends StatelessWidget {
  const ActivityTransactionTile(
      {super.key,
      required this.transaction,
      required this.currency,
      required this.onTap,
      this.hideAmounts = false});

  final TransactionModel transaction;
  final FiatCurrency currency;
  final VoidCallback onTap;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final colors = context.colors;
    final failed = tx.status == TransactionStatus.failed ||
        tx.status == TransactionStatus.cancelled;
    final settled = [
      TransactionStatus.completed,
      TransactionStatus.claimed,
      TransactionStatus.refunded
    ].contains(tx.status);
    final statusColor = failed
        ? colors.error
        : settled
            ? colors.success
            : colors.warning;
    final amount = hideAmounts
        ? '••••'
        : tx.isConversion
            ? '${_formatAsset(tx.sourceAmount, tx.sourceAsset)} to ${_formatAsset(tx.destinationAmount, tx.destinationAsset)}'
            : tx.isStablecoin
                ? _assetAmount(tx)
                : '${tx.isOutgoing ? '−' : '+'}${Formatters.formatSats(tx.amountSats)}';

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      tx.category == TransactionCategory.protected
                          ? Icons.shield_outlined
                          : tx.isConversion
                              ? Icons.swap_horiz
                              : tx.isOutgoing
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                      size: 20,
                      color: colors.textPrimary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(tx.recipientOrSender,
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                        '${tx.displayTitle} · ${Formatters.formatDate(tx.createdAt)}',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(amount,
                              style: AppTypography.titleSmall
                                  .copyWith(color: colors.textPrimary)),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        failed
                                            ? Icons.error_outline
                                            : settled
                                                ? Icons.check_circle_outline
                                                : Icons.schedule,
                                        size: 14,
                                        color: statusColor),
                                    const SizedBox(width: 5),
                                    Flexible(
                                        child: Text(tx.displayStatus,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                    color:
                                                        colors.textPrimary))),
                                  ])),
                        ]),
                    if (tx.status == TransactionStatus.uncertain) ...[
                      const SizedBox(height: 8),
                      Text(
                          'We are checking this payment. Do not send it again yet.',
                          style: AppTypography.bodySmall
                              .copyWith(color: colors.textSecondary)),
                    ],
                  ])),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.textSecondary, size: 18),
            ])));
  }

  String _assetAmount(TransactionModel tx) {
    final value = tx.isOutgoing ? tx.sourceAmount : tx.destinationAmount;
    final asset = tx.isOutgoing ? tx.sourceAsset : tx.destinationAsset;
    if (value == null || asset == null) return 'Amount unavailable';
    return '${tx.isOutgoing ? '−' : '+'}${_formatAsset(value, asset)}';
  }

  String _formatAsset(double? value, String? asset) {
    if (value == null || asset == null) return 'Amount unavailable';
    // The ledger stores Bitcoin conversion amounts in satoshis.
    if (asset == 'BTC') return Formatters.formatSats(value.toInt());
    return '${value.toStringAsFixed(2)} $asset';
  }
}
