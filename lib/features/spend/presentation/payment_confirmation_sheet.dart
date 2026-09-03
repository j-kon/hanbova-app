import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class PaymentConfirmationSheet extends StatefulWidget {
  final String title;
  final String billerName;
  final String accountReference;
  final String? accountHolderName;
  final double fiatAmount;
  final String fiatCurrency;
  final int amountSats;
  final int feeSats;
  final IconData serviceIcon;
  final String? planOrBouquetName;
  final Future<void> Function() onConfirm;

  const PaymentConfirmationSheet({
    super.key,
    required this.title,
    required this.billerName,
    required this.accountReference,
    this.accountHolderName,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.amountSats,
    this.feeSats = 50,
    required this.serviceIcon,
    this.planOrBouquetName,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String billerName,
    required String accountReference,
    String? accountHolderName,
    required double fiatAmount,
    required String fiatCurrency,
    required int amountSats,
    int feeSats = 50,
    required IconData serviceIcon,
    String? planOrBouquetName,
    required Future<void> Function() onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentConfirmationSheet(
        title: title,
        billerName: billerName,
        accountReference: accountReference,
        accountHolderName: accountHolderName,
        fiatAmount: fiatAmount,
        fiatCurrency: fiatCurrency,
        amountSats: amountSats,
        feeSats: feeSats,
        serviceIcon: serviceIcon,
        planOrBouquetName: planOrBouquetName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<PaymentConfirmationSheet> createState() =>
      _PaymentConfirmationSheetState();
}

class _PaymentConfirmationSheetState extends State<PaymentConfirmationSheet> {
  bool _isLoading = false;
  final NumberFormat _fiatFormat = NumberFormat('#,##0.00');

  String _formatFiat(double amount, String code) {
    final formatted = _fiatFormat.format(amount);
    switch (code.toUpperCase()) {
      case 'NGN':
        return '₦$formatted';
      case 'KES':
        return 'KSh $formatted';
      case 'GHS':
        return 'GH₵ $formatted';
      case 'RWF':
        return 'FRw $formatted';
      case 'UGX':
        return 'USh $formatted';
      case 'TZS':
        return 'TSh $formatted';
      case 'ZAR':
        return 'R $formatted';
      case 'USD':
      default:
        return '\$$formatted';
    }
  }

  Future<void> _handleConfirm() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSats = widget.amountSats + widget.feeSats;

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
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.darkTextSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _formatFiat(widget.fiatAmount, widget.fiatCurrency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatSats(widget.amountSats),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                _buildRow(
                  label: 'Biller / Service',
                  value: widget.billerName,
                  icon: widget.serviceIcon,
                ),
                const Divider(color: AppColors.darkBorder, height: 20),
                if (widget.planOrBouquetName != null) ...[
                  _buildRow(
                    label: 'Package / Plan',
                    value: widget.planOrBouquetName!,
                  ),
                  const Divider(color: AppColors.darkBorder, height: 20),
                ],
                _buildRow(
                  label: 'Account / Recipient',
                  value: widget.accountReference,
                  subtitle: widget.accountHolderName,
                ),
                const Divider(color: AppColors.darkBorder, height: 20),
                _buildRow(
                  label: 'Source',
                  value: 'Bitcoin Wallet',
                  valueColor: AppColors.primary,
                ),
                const Divider(color: AppColors.darkBorder, height: 20),
                _buildRow(
                  label: 'Network Fee',
                  value: Formatters.formatSats(widget.feeSats),
                ),
                const Divider(color: AppColors.darkBorder, height: 20),
                _buildRow(
                  label: 'Total Deducted',
                  value: Formatters.formatSats(totalSats),
                  isBold: true,
                  valueColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Safety Reassurance
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined,
                  size: 14, color: AppColors.darkTextSecondary),
              SizedBox(width: 6),
              Text(
                'Instant Bitcoin settlement • Direct to provider',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Confirm Action Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'Pay ${Formatters.formatSats(totalSats)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    String? subtitle,
    IconData? icon,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.darkTextSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
