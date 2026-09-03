import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transaction_receipt_sheet.dart';

class PaymentSuccessSheet extends StatefulWidget {
  final TransactionModel transaction;
  final String billerName;
  final String accountReference;
  final double fiatAmount;
  final String fiatCurrency;
  final int amountSats;
  final String? electricityTokenOrPin;
  final VoidCallback onDone;

  const PaymentSuccessSheet({
    super.key,
    required this.transaction,
    required this.billerName,
    required this.accountReference,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.amountSats,
    this.electricityTokenOrPin,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionModel transaction,
    required String billerName,
    required String accountReference,
    required double fiatAmount,
    required String fiatCurrency,
    required int amountSats,
    String? electricityTokenOrPin,
    required VoidCallback onDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PaymentSuccessSheet(
        transaction: transaction,
        billerName: billerName,
        accountReference: accountReference,
        fiatAmount: fiatAmount,
        fiatCurrency: fiatCurrency,
        amountSats: amountSats,
        electricityTokenOrPin: electricityTokenOrPin,
        onDone: onDone,
      ),
    );
  }

  @override
  State<PaymentSuccessSheet> createState() => _PaymentSuccessSheetState();
}

class _PaymentSuccessSheetState extends State<PaymentSuccessSheet> {
  bool _copiedToken = false;
  bool _saveBiller = true;

  void _copyToken() {
    if (widget.electricityTokenOrPin != null) {
      Clipboard.setData(ClipboardData(text: widget.electricityTokenOrPin!));
      setState(() => _copiedToken = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copiedToken = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorder, width: 1),
          left: BorderSide(color: AppColors.darkBorder, width: 1),
          right: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Badge
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Payment Successful',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Settled instantly via Bitcoin satoshis',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Token Display Box (If electricity or voucher PIN)
          if (widget.electricityTokenOrPin != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'ELECTRICITY RECHARGE TOKEN',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    widget.electricityTokenOrPin!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _copyToken,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copiedToken ? Icons.check : Icons.copy,
                            size: 14,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _copiedToken ? 'Copied to Clipboard' : 'Copy Token',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Biller', widget.billerName),
                const SizedBox(height: 10),
                _buildSummaryRow('Account / Number', widget.accountReference),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  'Amount Paid',
                  '${Formatters.formatSats(widget.amountSats)} sats',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save Biller Checkbox Row
          GestureDetector(
            onTap: () => setState(() => _saveBiller = !_saveBiller),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _saveBiller,
                    activeColor: AppColors.primary,
                    checkColor: Colors.black,
                    onChanged: (val) =>
                        setState(() => _saveBiller = val ?? true),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Save to Pay Again billers for quick repeat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          OutlinedButton.icon(
            onPressed: () {
              final curr = FiatCurrency.values.firstWhere(
                (c) =>
                    c.code.toUpperCase() == widget.fiatCurrency.toUpperCase(),
                orElse: () => FiatCurrency.ngn,
              );
              TransactionReceiptSheet.show(
                context,
                widget.transaction,
                curr,
              );
            },
            icon: const Icon(Icons.receipt_long,
                size: 18, color: AppColors.primary),
            label: const Text(
              'View Official Receipt',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.primary : Colors.white,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class PaymentUncertainSheet extends StatelessWidget {
  final String billerName;
  final String accountReference;
  final int amountSats;
  final VoidCallback onViewPending;
  final VoidCallback onDone;

  const PaymentUncertainSheet({
    super.key,
    required this.billerName,
    required this.accountReference,
    required this.amountSats,
    required this.onViewPending,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required String billerName,
    required String accountReference,
    required int amountSats,
    required VoidCallback onViewPending,
    required VoidCallback onDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentUncertainSheet(
        billerName: billerName,
        accountReference: accountReference,
        amountSats: amountSats,
        onViewPending: onViewPending,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.warning, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.warning,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Payment Processing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Reassurance Safety Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Checking payment status with biller. Please don\'t pay again yet. We will update you immediately once confirmed.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onViewPending();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View in Pending Centre',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDone();
            },
            child: const Text(
              'Return to Home',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentFailedSheet extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const PaymentFailedSheet({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String errorMessage,
    required VoidCallback onRetry,
    required VoidCallback onDismiss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentFailedSheet(
        errorMessage: errorMessage,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Payment Could Not Be Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No Bitcoin satoshis were deducted from your wallet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss();
            },
            child: const Text(
              'Dismiss',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
