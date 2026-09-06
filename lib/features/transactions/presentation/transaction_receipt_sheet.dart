import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionReceiptSheet extends StatelessWidget {
  final TransactionModel transaction;
  final FiatCurrency currency;

  const TransactionReceiptSheet({
    super.key,
    required this.transaction,
    required this.currency,
  });

  static void show(
    BuildContext context,
    TransactionModel transaction,
    FiatCurrency currency,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionReceiptSheet(
        transaction: transaction,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final numFormat = NumberFormat('#,###');
    final dateStr =
        DateFormat('MMMM d, yyyy • h:mm a').format(transaction.createdAt);

    final (typeTitle, typeIcon, typeColor) = _getTypeVisuals(transaction.type);
    final isUncertain = transaction.status == TransactionStatus.uncertain;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header Visual
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 28),
          ),
          const SizedBox(height: 12),

          Text(
            typeTitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            '${numFormat.format(transaction.amountSats)} sats',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '≈ ${currency.format(transaction.amountSats)}',
            style: TextStyle(
              color: colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUncertain
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUncertain
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
            child: Text(
              isUncertain
                  ? '⚠️ Status Uncertain (Checking with Provider)'
                  : 'Completed Successfully',
              style: TextStyle(
                color: isUncertain
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 14),

          // Receipt Breakdown Items
          _buildReceiptRow('Transaction ID', transaction.id,
              isCopyable: true, context: context),
          _buildReceiptRow('Date & Time', dateStr, context: context),
          _buildReceiptRow(
              'Recipient / Description', transaction.recipientOrSender,
              context: context),
          _buildReceiptRow('Network Fee', '${transaction.feeSats ?? 0} sats',
              context: context),
          _buildReceiptRow('Underlying Asset', 'Bitcoin (100% Sats)',
              context: context),

          if (transaction.type == TransactionType.electricity &&
              transaction.recipientOrSender.contains('Electricity')) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prepaid Electricity Token',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '4819-2049-1829-4019-3918',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16, color: colors.primary),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                          text: '4819-2049-1829-4019-3918'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Token copied to clipboard!'),
                          backgroundColor: colors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Need Help Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showNeedHelpSheet(context),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Need help with this transaction?'),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isCopyable = false, required BuildContext context}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                value.length > 28 ? '${value.substring(0, 25)}...' : value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard!'),
                        backgroundColor: colors.primary,
                      ),
                    );
                  },
                  child: Icon(Icons.copy, size: 13, color: colors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _getTypeVisuals(TransactionType type) {
    switch (type) {
      case TransactionType.bitcoinReceived:
      case TransactionType.bitcoinSent:
      case TransactionType.instantReceive:
      case TransactionType.instantSend:
        return (
          'Bitcoin Transfer',
          Icons.currency_bitcoin,
          const Color(0xFF10B981)
        );
      case TransactionType.protectedPayment:
      case TransactionType.protectedSend:
      case TransactionType.protectedClaim:
      case TransactionType.protectedRefund:
        return (
          'Protected Payment',
          Icons.shield_outlined,
          const Color(0xFF38BDF8)
        );
      case TransactionType.airtime:
      case TransactionType.data:
      case TransactionType.electricity:
      case TransactionType.water:
      case TransactionType.tv:
      case TransactionType.internet:
        return (
          'Bill & Utility Recharge',
          Icons.flash_on_outlined,
          const Color(0xFFEAB308)
        );
      case TransactionType.esimPurchase:
      case TransactionType.esimTopup:
        return (
          'Travel & eSIM Data',
          Icons.flight_takeoff_outlined,
          const Color(0xFF8B5CF6)
        );
      case TransactionType.cardFunding:
      case TransactionType.cardPayment:
      case TransactionType.cardRefund:
        return (
          'Virtual Card Payment',
          Icons.credit_card_outlined,
          const Color(0xFFEC4899)
        );
      case TransactionType.bankPayout:
      case TransactionType.mobileMoneyPayout:
        return (
          'Corridor Payout',
          Icons.account_balance,
          const Color(0xFF38BDF8)
        );
      case TransactionType.usdtSent:
      case TransactionType.usdtReceived:
        return (
          'Tether USD Transfer',
          Icons.attach_money_rounded,
          const Color(0xFF26A17B),
        );
      case TransactionType.usdcSent:
      case TransactionType.usdcReceived:
        return (
          'USD Coin Transfer',
          Icons.monetization_on_rounded,
          const Color(0xFF2775CA),
        );
      case TransactionType.btcToUsdtConversion:
      case TransactionType.btcToUsdcConversion:
      case TransactionType.usdtToBtcConversion:
      case TransactionType.usdcToBtcConversion:
      case TransactionType.usdtToUsdcConversion:
      case TransactionType.usdcToUsdtConversion:
        return (
          'Asset Conversion',
          Icons.swap_horiz_rounded,
          const Color(0xFF38BDF8),
        );
    }
  }

  void _showNeedHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final helpColors = ctx.colors;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: helpColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need Help with Transaction',
                style: TextStyle(
                  color: helpColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an issue category below to get transaction support.',
                style: TextStyle(color: helpColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                  ctx, 'Payment not received by merchant / recipient'),
              _buildHelpOption(ctx, 'Meter token not generating electricity'),
              _buildHelpOption(ctx, 'eSIM QR code not scanning or activating'),
              _buildHelpOption(
                  ctx, 'Protected payment protection window dispute'),
              _buildHelpOption(ctx, 'Other general transaction inquiry'),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpOption(BuildContext context, String text) {
    final helpColors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.support_agent_outlined, color: helpColors.primary),
      title: Text(text,
          style: TextStyle(color: helpColors.textPrimary, fontSize: 13)),
      trailing:
          Icon(Icons.chevron_right, color: helpColors.textSecondary, size: 18),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support ticket opened: "$text"'),
            backgroundColor: helpColors.primary,
          ),
        );
      },
    );
  }
}
