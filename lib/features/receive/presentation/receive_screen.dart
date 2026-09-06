import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/domain/asset_model.dart';
import '../domain/deposit_controller.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  final AssetType initialAsset;

  const ReceiveScreen({super.key, this.initialAsset = AssetType.btc});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late AssetType _selectedAsset;
  static const String _defaultStablecoinNetwork = 'TRC-20';
  static const String _defaultTronAddress =
      'TL7bQ746QzT185cZ2G8N8dK9z9Q8eJ6K7L';
  final _amountController = TextEditingController(text: '10000');
  Timer? _quoteDebounce;

  static const List<int> _quickSatPresets = [5000, 10000, 25000, 50000];

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.initialAsset;
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateInvoice() async {
    final sats = int.tryParse(_amountController.text.trim());
    if (sats == null || sats <= 0) {
      ref.read(depositControllerProvider).reset();
      return;
    }
    try {
      await ref.read(depositControllerProvider).createQuote(sats);
    } catch (_) {}
  }

  void _scheduleInvoice(String value) {
    _quoteDebounce?.cancel();
    ref.read(depositControllerProvider).reset();
    if ((int.tryParse(value.trim()) ?? 0) <= 0) return;
    _quoteDebounce = Timer(
      const Duration(milliseconds: 400),
      _generateInvoice,
    );
  }

  Future<void> _checkAndMint() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final controller = ref.read(depositControllerProvider);
      final quoteId = controller.state.quote?.quoteId;
      final minted = await controller.checkAndMint();
      if (minted == null || quoteId == null) return;
      ref.invalidate(cashuBalanceProvider);

      await ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'mint_$quoteId',
              type: TransactionType.instantReceive,
              status: TransactionStatus.completed,
              amountSats: minted,
              recipientOrSender: 'Cashu Mint',
              description:
                  'Minted ${Formatters.formatSats(minted)} from paid Lightning invoice',
              createdAt: DateTime.now(),
            ),
          );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Minted ${Formatters.formatSats(minted)} successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.go('/home');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Receive ${_selectedAsset.symbol}',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Asset Selection Prompt
              Text(
                'What are you receiving?',
                style: AppTypography.titleSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Asset Chips
              Row(
                children: [
                  _buildAssetChip(AssetType.btc, colors),
                  const SizedBox(width: 8),
                  _buildAssetChip(AssetType.usdt, colors),
                  const SizedBox(width: 8),
                  _buildAssetChip(AssetType.usdc, colors),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Asset Specific Receive View
              if (_selectedAsset == AssetType.btc)
                _buildBitcoinReceiveView(colors, isDark)
              else
                _buildStablecoinReceiveView(colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetChip(AssetType asset, HanbovaColors colors) {
    final isSelected = _selectedAsset == asset;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAsset = asset;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? asset.color : colors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? asset.color : colors.border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: asset.color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              asset.icon,
              size: 16,
              color: isSelected ? Colors.white : asset.color,
            ),
            const SizedBox(width: 6),
            Text(
              asset.symbol,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitcoinReceiveView(HanbovaColors colors, bool isDark) {
    final currency = ref.watch(currencyProvider);
    final rateProvider = ref.watch(exchangeRateProvider);
    final currentSats = int.tryParse(_amountController.text.trim()) ?? 0;
    final deposit = ref.watch(depositControllerProvider).state;
    final generatedInvoice = deposit.quote?.bolt11Invoice ?? '';
    final isGenerating = deposit.phase == DepositPhase.loading;
    final isChecking = deposit.phase == DepositPhase.checking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount Entry Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Amount',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '≈ ${currency.format(currentSats, rateProvider)}',
                    style: AppTypography.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (sats)',
                  suffixText: currency.format(currentSats),
                  prefixIcon: Icon(
                    Icons.currency_bitcoin_rounded,
                    color: colors.primary,
                  ),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                onChanged: _scheduleInvoice,
              ),
              const SizedBox(height: 10),
              // Preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickSatPresets.map((preset) {
                    final isCurrent = currentSats == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _amountController.text = preset.toString();
                            _generateInvoice();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? colors.primary.withValues(alpha: 0.15)
                                : colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? colors.primary
                                  : colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            '${Formatters.formatSatsNumber(preset)} sats',
                            style: TextStyle(
                              color: isCurrent
                                  ? colors.primary
                                  : colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        ElevatedButton.icon(
          onPressed: isGenerating ? null : _generateInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bitcoinOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          ),
          icon: isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.qr_code_2_rounded, size: 20),
          label: const Text(
            'Generate Lightning Invoice',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // QR Code Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: colors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 224,
                width: 224,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : generatedInvoice.isNotEmpty
                        ? QrImageView(
                            data: generatedInvoice,
                            version: QrVersions.auto,
                            size: 200,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter an amount to generate invoice',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Lightning Invoice (NUT-04)',
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pay with any Lightning wallet to mint spendable ecash',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (generatedInvoice.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.xsRadius,
                    border: Border.all(color: colors.border),
                  ),
                  child: SelectableText(
                    generatedInvoice.length > 36
                        ? '${generatedInvoice.substring(0, 32)}...'
                        : generatedInvoice,
                    style: AppTypography.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      color: colors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: generatedInvoice));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice copied to clipboard'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy invoice'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (deposit.quote != null && deposit.phase != DepositPhase.minted)
          ElevatedButton.icon(
            onPressed: isChecking ? null : _checkAndMint,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            icon: isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Check Payment & Mint Ecash',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        if (deposit.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            deposit.message!,
            style: AppTypography.bodySmall.copyWith(
              color: deposit.phase == DepositPhase.failed ||
                      deposit.phase == DepositPhase.expired
                  ? colors.error
                  : colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStablecoinReceiveView(HanbovaColors colors, bool isDark) {
    const address = _defaultTronAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Strong Same-Network Warning Alert (Strict Test Contract Requirement)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.12),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.danger, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Same-Network Warning',
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only send ${_selectedAsset.symbol} over the $_defaultStablecoinNetwork (Tron) network. Sending funds over any other network or sending a different asset will result in permanent loss.',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // QR Code & Address Box
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color:
                  _selectedAsset.color.withValues(alpha: isDark ? 0.35 : 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 200,
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_selectedAsset.icon,
                      size: 18, color: _selectedAsset.color),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedAsset.symbol} Deposit Address',
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: AppRadius.xsRadius,
                  border: Border.all(color: colors.border),
                ),
                child: SelectableText(
                  address,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_selectedAsset.symbol} address copied to clipboard',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copy Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAsset.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
