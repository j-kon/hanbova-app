import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../wallet/domain/asset_model.dart';

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
  AssetType _selectedAsset = AssetType.btc;
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
    final usdEstimate = (widget.amountSats / 100000000.0) * 65000.0;

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
                      Icon(
                        _selectedAsset == AssetType.btc
                            ? Icons.bolt
                            : Icons.attach_money_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedAsset == AssetType.btc
                            ? Formatters.formatSats(widget.amountSats)
                            : '≈ \$${usdEstimate.toStringAsFixed(2)} ${_selectedAsset.symbol}',
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
          const SizedBox(height: 16),

          // Pay With Selector
          const Text(
            'Pay with',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPayWithOption(
                asset: AssetType.btc,
                label: 'Bitcoin',
                sublabel: '${Formatters.formatSats(widget.amountSats)} sats',
                isSelected: _selectedAsset == AssetType.btc,
              ),
              const SizedBox(width: 8),
              _buildPayWithOption(
                asset: AssetType.usdt,
                label: 'USDT',
                sublabel: '\$${usdEstimate.toStringAsFixed(2)}',
                isSelected: _selectedAsset == AssetType.usdt,
              ),
              const SizedBox(width: 8),
              _buildPayWithOption(
                asset: AssetType.usdc,
                label: 'USDC',
                sublabel: '\$${usdEstimate.toStringAsFixed(2)}',
                isSelected: _selectedAsset == AssetType.usdc,
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                  label: 'Payment Method',
                  value: '${_selectedAsset.name} Wallet',
                  valueColor: _selectedAsset.color,
                ),
                if (_selectedAsset.isStablecoin) ...[
                  const Divider(color: AppColors.darkBorder, height: 20),
                  _buildRow(
                    label: 'Conversion Path',
                    value:
                        '${_selectedAsset.symbol} → USD (\$${usdEstimate.toStringAsFixed(2)}) → ${widget.fiatCurrency}',
                    subtitle: 'Normalized multi-rail settlement',
                  ),
                ],
                const Divider(color: AppColors.darkBorder, height: 20),
                _buildRow(
                  label: 'Network Fee',
                  value: _selectedAsset == AssetType.btc
                      ? Formatters.formatSats(widget.feeSats)
                      : '≈ \$0.05 ${_selectedAsset.symbol}',
                  subtitle: 'Estimated sample fee',
                ),
                const Divider(color: AppColors.darkBorder, height: 20),
                _buildRow(
                  label: 'Total Deducted',
                  value: _selectedAsset == AssetType.btc
                      ? Formatters.formatSats(totalSats)
                      : '≈ \$${(usdEstimate + 0.05).toStringAsFixed(2)} ${_selectedAsset.symbol}',
                  isBold: true,
                  valueColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Safety Reassurance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 14, color: AppColors.darkTextSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _selectedAsset == AssetType.btc
                      ? 'Instant Bitcoin settlement • Direct to provider'
                      : 'Provider-neutral stablecoin route • Instant settlement',
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedAsset == AssetType.btc
                            ? Icons.bolt
                            : Icons.check_circle_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedAsset == AssetType.btc
                            ? 'Pay ${Formatters.formatSats(totalSats)}'
                            : 'Pay \$${(usdEstimate + 0.05).toStringAsFixed(2)} ${_selectedAsset.symbol}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayWithOption({
    required AssetType asset,
    required String label,
    required String sublabel,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAsset = asset;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? asset.color.withValues(alpha: 0.15)
                : AppColors.darkCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? asset.color : AppColors.darkBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(asset.icon,
                  size: 20,
                  color: isSelected ? asset.color : AppColors.darkTextSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  color: isSelected ? asset.color : AppColors.darkTextSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isBold ? Colors.white : AppColors.darkTextSecondary,
                  fontSize: isBold ? 14 : 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: valueColor ?? Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
