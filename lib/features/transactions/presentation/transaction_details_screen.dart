import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../domain/transaction_model.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  bool _revealClaimCode = false;

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  String _maskClaimCode(String code) {
    if (code.length <= 8) return '••••••••';
    final prefix = code.startsWith('hnbv_claim_')
        ? 'hnbv_claim_'
        : code.substring(0, min(4, code.length));
    final suffix = code.substring(max(0, code.length - 4));
    return '$prefix••••••••$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);
    final tx = widget.transaction;

    Color statusColor;
    switch (tx.status) {
      case TransactionStatus.completed:
      case TransactionStatus.claimed:
        statusColor = AppColors.success;
        break;
      case TransactionStatus.waitingForRecipient:
      case TransactionStatus.claimable:
        statusColor = AppColors.primary;
        break;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
      case TransactionStatus.refunding:
      case TransactionStatus.uncertain:
        statusColor = AppColors.warning;
        break;
      case TransactionStatus.refundAvailable:
      case TransactionStatus.expired:
      case TransactionStatus.refunded:
        statusColor = AppColors.primary;
        break;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        statusColor = AppColors.danger;
        break;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
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
              // 1. Primary Receipt Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: colors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      '${tx.isOutgoing ? '-' : '+'}${Formatters.formatSats(tx.amountSats)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.fiatAmount != null && tx.fiatCurrency != null
                          ? '${tx.fiatCurrency} ${tx.fiatAmount!.toStringAsFixed(2)}'
                          : currency.format(tx.amountSats),
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tx.displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: colors.divider),
                    const SizedBox(height: 16),

                    // Adaptive Detail Rows
                    _buildDetailRow(
                      label: tx.isOutgoing ? 'Recipient / Merchant' : 'Sender',
                      value: tx.recipientOrSender,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      label: 'Payment Category',
                      value: tx.displayTitle,
                    ),
                    const SizedBox(height: 12),

                    if (tx.billerName != null) ...[
                      _buildDetailRow(
                        label: 'Biller / Provider',
                        value: tx.billerName!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (tx.accountReference != null) ...[
                      _buildDetailRow(
                        label: 'Account Reference',
                        value: tx.accountReference!,
                        onCopy: () =>
                            _copy('Account Reference', tx.accountReference!),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (tx.spendCountry != null) ...[
                      _buildDetailRow(
                        label: 'Country Rail',
                        value: tx.spendCountry!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (tx.paymentMethod != null) ...[
                      _buildDetailRow(
                        label: 'Payment Method',
                        value: tx.paymentMethod!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (tx.feeSats != null && tx.feeSats! > 0) ...[
                      _buildDetailRow(
                        label: 'Network Fee',
                        value: '${tx.feeSats} sats',
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildDetailRow(
                      label: 'Timestamp',
                      value: Formatters.formatDate(tx.createdAt),
                    ),

                    if (tx.expiresAt != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        label: 'Locktime Expiry',
                        value: Formatters.formatDate(tx.expiresAt!),
                      ),
                    ],

                    if (tx.receiptReference != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        label: 'Receipt Reference',
                        value: tx.receiptReference!,
                        onCopy: () =>
                            _copy('Receipt Reference', tx.receiptReference!),
                      ),
                    ],

                    if (tx.claimReference != null) ...[
                      const SizedBox(height: 12),
                      _buildMaskedDetailRow(
                        label: 'Claim Code',
                        maskedValue: _maskClaimCode(tx.claimReference!),
                        fullValue: tx.claimReference!,
                        isRevealed: _revealClaimCode,
                        onToggleReveal: () => setState(
                            () => _revealClaimCode = !_revealClaimCode),
                        onCopy: () => _copy('Claim Code', tx.claimReference!),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Electricity / Meter Token Card (if available)
              if (tx.tokenOrPin != null && tx.tokenOrPin!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Prepaid Meter Token',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tx.tokenOrPin!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                          side: const BorderSide(color: Colors.amberAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Token for Meter'),
                        onPressed: () => _copy('Meter Token', tx.tokenOrPin!),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. Protected Send Info Card
              if (tx.type == TransactionType.protectedPayment ||
                  tx.type == TransactionType.protectedSend ||
                  tx.type == TransactionType.protectedClaim ||
                  tx.type == TransactionType.protectedRefund) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Protected Payment Protection',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tx.status == TransactionStatus.refundAvailable ||
                                tx.status == TransactionStatus.expired
                            ? 'The locktime has passed and the payment was not claimed. You can claim your refund to return the funds to your spendable balance.'
                            : (tx.status == TransactionStatus.claimed
                                ? 'The recipient has claimed this payment. It is now completed and settled.'
                                : 'Funds are held with claim and refund safeguards. If the recipient does not claim before the locktime expires, you gain a refund path.'),
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCopy,
                  child: const Icon(Icons.copy,
                      size: 14, color: AppColors.darkTextSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaskedDetailRow({
    required String label,
    required String maskedValue,
    required String fullValue,
    required bool isRevealed,
    required VoidCallback onToggleReveal,
    required VoidCallback onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  isRevealed ? fullValue : maskedValue,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: isRevealed ? null : 'monospace',
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onToggleReveal,
                child: Icon(
                  isRevealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy,
                    size: 14, color: AppColors.darkTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
