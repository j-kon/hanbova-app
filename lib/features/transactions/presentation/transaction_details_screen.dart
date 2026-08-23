import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../domain/transaction_model.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final TransactionModel tx;

  const TransactionDetailsScreen({super.key, required this.tx});

  @override
  ConsumerState<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends ConsumerState<TransactionDetailsScreen> {
  bool _showDevDetails = false;

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);
    final isDev = ref.watch(appConfigProvider).isDevelopment;
    final tx = widget.tx;

    Color statusColor;
    String statusText;

    switch (tx.status) {
      case TransactionStatus.completed:
        statusColor = colors.success;
        statusText = 'Completed';
        break;
      case TransactionStatus.claimable:
        statusColor = colors.protected;
        statusText = 'Claimable';
        break;
      case TransactionStatus.pending:
        statusColor = colors.warning;
        statusText = 'Pending';
        break;
      case TransactionStatus.refunded:
        statusColor = colors.primary;
        statusText = 'Refunded';
        break;
      case TransactionStatus.expired:
        statusColor = colors.textTertiary;
        statusText = 'Expired';
        break;
      case TransactionStatus.failed:
        statusColor = colors.error;
        statusText = 'Failed';
        break;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: colors.border, width: 1),
                ),
                child: Column(
                  children: [
                    // Amount header
                    Text(
                      Formatters.formatSats(tx.amountSats),
                      style: AppTypography.display.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(tx.amountSats),
                      style: AppTypography.titleSmall.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.fullRadius,
                      ),
                      child: Text(
                        statusText,
                        style: AppTypography.labelMedium.copyWith(color: statusColor),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Divider(color: colors.divider),
                    const SizedBox(height: AppSpacing.md),

                    // Row details
                    _DetailRow(
                      label: tx.isOutgoing ? 'Recipient' : 'Sender',
                      value: tx.recipientOrSender,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _DetailRow(
                      label: 'Payment Type',
                      value: tx.type == TransactionType.protectedSend ? 'Protected Send (Cashu P2PK)' : 'Instant Send (Lightning)',
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _DetailRow(
                      label: 'Date & Time',
                      value: Formatters.formatDate(tx.createdAt),
                    ),

                    if (tx.expiresAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        label: 'Locktime Expiry',
                        value: Formatters.formatDate(tx.expiresAt!),
                      ),
                    ],

                    if (tx.claimReference != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        label: 'Claim Reference',
                        value: tx.claimReference!,
                        onCopy: () => _copy('Claim Reference', tx.claimReference!),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Transaction ID',
                      value: tx.id,
                      onCopy: () => _copy('Transaction ID', tx.id),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Developer Technical Details (Collapsible)
              if (isDev) ...[
                Material(
                  color: colors.surfaceElevated,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    onTap: () => setState(() => _showDevDetails = !_showDevDetails),
                    borderRadius: AppRadius.mdRadius,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.code, color: colors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Developer Technical Details',
                              style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                            ),
                          ),
                          Icon(
                            _showDevDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showDevDetails) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DevRow(label: 'Protocol Specs', value: 'Cashu NUT-10 (Conditions) / NUT-11 (P2PK)'),
                        _DevRow(label: 'Token State Check', value: 'NUT-07 Mint Verify'),
                        _DevRow(label: 'Mint Endpoint', value: 'http://127.0.0.1:3338'),
                        _DevRow(label: 'Spending Path', value: 'Recipient PubKey | Locktime -> Sender Refund'),
                        _DevRow(label: 'Double Spend Rule', value: 'First valid spend confirmed at mint wins'),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(Icons.copy, size: 14, color: colors.primary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DevRow extends StatelessWidget {
  final String label;
  final String value;

  const _DevRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: colors.textTertiary, fontSize: 10),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }
}
