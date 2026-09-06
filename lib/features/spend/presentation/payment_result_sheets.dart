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
  final String? serviceTitle;
  final VoidCallback onDone;
  final VoidCallback? onBuyAgain;

  const PaymentSuccessSheet({
    super.key,
    required this.transaction,
    required this.billerName,
    required this.accountReference,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.amountSats,
    this.electricityTokenOrPin,
    this.serviceTitle,
    required this.onDone,
    this.onBuyAgain,
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
    String? serviceTitle,
    required VoidCallback onDone,
    VoidCallback? onBuyAgain,
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
        serviceTitle: serviceTitle,
        onDone: onDone,
        onBuyAgain: onBuyAgain,
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

  String _formatFiat(double amount, String currencyCode) {
    final formatted = Formatters.formatSatsNumber(amount.round());
    switch (currencyCode.toUpperCase()) {
      case 'NGN':
        return '₦$formatted';
      case 'KES':
        return 'KSh $formatted';
      case 'GHS':
        return 'GH₵ $formatted';
      case 'USD':
      default:
        return '\$$formatted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = widget.serviceTitle ?? 'Payment Successful';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
          left: BorderSide(color: colors.border, width: 1),
          right: BorderSide(color: colors.border, width: 1),
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
          // 1. Success Icon
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Title & Big Fiat Amount
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _formatFiat(widget.fiatAmount, widget.fiatCurrency),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Recipient and Provider Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android_rounded,
                        size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      widget.accountReference,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.billerName,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Token Display Box (If electricity or voucher PIN)
          if (widget.electricityTokenOrPin != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ELECTRICITY RECHARGE TOKEN',
                        style: TextStyle(
                          color: colors.primary,
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
                    style: TextStyle(
                      color: colors.textPrimary,
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
                        color: colors.primary,
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

          // Details summary card (Bitcoin settlement accounting)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: colors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Bitcoin Settled',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatSats(widget.amountSats),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

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
                    activeColor: colors.primary,
                    checkColor: Colors.black,
                    onChanged: (val) =>
                        setState(() => _saveBiller = val ?? true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Save to Pay Again for quick repeat',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Primary CTA: [ Done ]
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
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
          const SizedBox(height: 10),

          // 5. Secondary Row: View Receipt & Buy Again
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    final curr = FiatCurrency.values.firstWhere(
                      (c) =>
                          c.code.toUpperCase() ==
                          widget.fiatCurrency.toUpperCase(),
                      orElse: () => FiatCurrency.ngn,
                    );
                    TransactionReceiptSheet.show(
                      context,
                      widget.transaction,
                      curr,
                    );
                  },
                  icon: Icon(Icons.receipt_long_outlined,
                      size: 16, color: colors.primary),
                  label: Text(
                    'View receipt',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (widget.onBuyAgain != null) ...[
                Container(height: 16, width: 1, color: colors.border),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onBuyAgain!();
                    },
                    icon: Icon(Icons.refresh_rounded,
                        size: 16, color: colors.primary),
                    label: Text(
                      'Buy again',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentUncertainSheet extends StatelessWidget {
  final TransactionModel transaction;
  final String billerName;
  final double fiatAmount;
  final String fiatCurrency;
  final int amountSats;
  final VoidCallback onDone;

  const PaymentUncertainSheet({
    super.key,
    required this.transaction,
    required this.billerName,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.amountSats,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionModel transaction,
    required String billerName,
    required double fiatAmount,
    required String fiatCurrency,
    required int amountSats,
    required VoidCallback onDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PaymentUncertainSheet(
        transaction: transaction,
        billerName: billerName,
        fiatAmount: fiatAmount,
        fiatCurrency: fiatCurrency,
        amountSats: amountSats,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
          left: BorderSide(color: colors.border, width: 1),
          right: BorderSide(color: colors.border, width: 1),
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
              width: 60,
              height: 60,
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
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Payment Processing',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Awaiting confirmation from provider',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Please Do Not Pay Again',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment was transmitted and satoshis reserved. The provider response is taking slightly longer than normal. Hanbova is continuously verifying the delivery.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Track in Pending Centre',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentFailedSheet extends StatelessWidget {
  final String billerName;
  final String errorMessage;
  final VoidCallback onRetry;

  const PaymentFailedSheet({
    super.key,
    required this.billerName,
    required this.errorMessage,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required String billerName,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentFailedSheet(
        billerName: billerName,
        errorMessage: errorMessage,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
          left: BorderSide(color: colors.border, width: 1),
          right: BorderSide(color: colors.border, width: 1),
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
              width: 60,
              height: 60,
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
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Payment Failed',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
