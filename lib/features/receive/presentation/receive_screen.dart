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
import '../domain/deposit_controller.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';

import '../../wallet/domain/asset_model.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  final AssetType initialAsset;

  const ReceiveScreen({super.key, this.initialAsset = AssetType.btc});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late AssetType _selectedAsset;
  String _selectedNetwork = 'Polygon';
  final _amountController = TextEditingController(text: '10000');
  Timer? _quoteDebounce;

  static const Map<String, String> _stablecoinAddresses = {
    'Polygon': '0x71C63B2945D771F524A1a73B5B84F09069d45eA7',
    'Tron (TRC-20)': 'TL7bQ746QzT185cZ2G8N8dK9z9Q8eJ6K7L',
    'Ethereum (ERC-20)': '0x71C63B2945D771F524A1a73B5B84F09069d45eA7',
  };

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
                  'Minted ${Formatters.formatSats(minted)} successfully!')),
        );
        context.go('/home');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Receive ${_selectedAsset.symbol}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Asset Selection
              Text(
                'What are you receiving?',
                style: AppTypography.titleSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
                _buildBitcoinReceiveView(colors)
              else
                _buildStablecoinReceiveView(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetChip(AssetType asset, HanbovaColors colors) {
    final isSelected = _selectedAsset == asset;
    return ChoiceChip(
      label: Text(
        asset.symbol,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(asset.icon,
          size: 16, color: isSelected ? Colors.white : asset.color),
      selected: isSelected,
      selectedColor: asset.color,
      backgroundColor: colors.surfaceCard,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAsset = asset;
          });
        }
      },
    );
  }

  Widget _buildBitcoinReceiveView(HanbovaColors colors) {
    final currency = ref.watch(currencyProvider);
    final currentSats = int.tryParse(_amountController.text.trim()) ?? 0;
    final deposit = ref.watch(depositControllerProvider).state;
    final generatedInvoice = deposit.quote?.bolt11Invoice ?? '';
    final isGenerating = deposit.phase == DepositPhase.loading;
    final isChecking = deposit.phase == DepositPhase.checking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount field
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (sats)',
            suffixText: currency.format(currentSats),
            prefixIcon: const Icon(Icons.currency_bitcoin_rounded),
          ),
          onChanged: _scheduleInvoice,
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: isGenerating ? null : _generateInvoice,
          icon: isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code_2_rounded),
          label: const Text('Generate Lightning Invoice'),
        ),
        const SizedBox(height: AppSpacing.lg),

        // QR Code Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: colors.border, width: 1),
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
                        : Text(
                            'Enter an amount to generate invoice',
                            style: AppTypography.bodySmall
                                .copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Lightning Invoice (NUT-04)',
                style: AppTypography.titleSmall
                    .copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Pay with any Lightning wallet to mint spendable ecash',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textSecondary),
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
                  ),
                  child: SelectableText(
                    generatedInvoice.length > 36
                        ? '${generatedInvoice.substring(0, 32)}...'
                        : generatedInvoice,
                    style: AppTypography.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      color: colors.textTertiary,
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
                              content: Text('Invoice copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
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
            icon: isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Check Payment & Mint Ecash'),
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

  Widget _buildStablecoinReceiveView(HanbovaColors colors) {
    final address = _stablecoinAddresses[_selectedNetwork] ??
        '0x71C63B2945D771F524A1a73B5B84F09069d45eA7';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Network Selector Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedNetwork,
          decoration: InputDecoration(
            labelText: 'Deposit Network',
            border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
          ),
          dropdownColor: colors.surfaceCard,
          items: _stablecoinAddresses.keys.map((net) {
            return DropdownMenuItem(
              value: net,
              child: Text(net, style: TextStyle(color: colors.textPrimary)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedNetwork = val);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Strong Same-Network Warning Alert
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
                      'Only send ${_selectedAsset.symbol} over the $_selectedNetwork network. Sending funds over any other network or sending a different asset will result in permanent loss.',
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
            border: Border.all(color: colors.border),
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
                ),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${_selectedAsset.symbol} Deposit Address',
                style: AppTypography.titleSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: AppRadius.xsRadius,
                  border: Border.all(color: colors.border),
                ),
                child: SelectableText(
                  address,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
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
                            '${_selectedAsset.symbol} address copied to clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAsset.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smRadius),
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
