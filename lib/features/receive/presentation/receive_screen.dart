import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/lightning/lightning_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
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
  String _generatedInvoice = '';
  String? _quoteId;
  bool _isGenerating = false;
  bool _isChecking = false;

  static const Map<String, String> _stablecoinAddresses = {
    'Polygon': '0x71C63B2945D771F524A1a73B5B84F09069d45eA7',
    'Tron (TRC-20)': 'TL7bQ746QzT185cZ2G8N8dK9z9Q8eJ6K7L',
    'Ethereum (ERC-20)': '0x71C63B2945D771F524A1a73B5B84F09069d45eA7',
  };

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.initialAsset;
    _generateInvoice();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateInvoice() async {
    final sats = int.tryParse(_amountController.text.trim()) ?? 10000;
    setState(() {
      _isGenerating = true;
      _generatedInvoice = '';
      _quoteId = null;
    });

    try {
      final cashuWallet = ref.read(cashuWalletServiceProvider);
      if (cashuWallet != null) {
        final quote = await cashuWallet.createMintQuote(sats);
        if (mounted) {
          setState(() {
            _quoteId = quote.quoteId;
            _generatedInvoice = quote.bolt11Invoice;
            _isGenerating = false;
          });
        }
      } else {
        final lightningService = ref.read(lightningServiceProvider);
        final invoice = await lightningService.createInvoice(
          amountSats: sats,
          description: 'Hanbova Lightning Receive ($sats sats)',
        );
        if (mounted && invoice.bolt11.isNotEmpty) {
          setState(() {
            _generatedInvoice = invoice.bolt11;
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receive invoice: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _checkAndMint() async {
    if (_quoteId == null || _quoteId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active mint quote to check')),
      );
      return;
    }

    setState(() => _isChecking = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final cashuWallet = ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError('Cashu wallet not initialized');
      }

      final minted = await cashuWallet.mintQuote(_quoteId!);
      ref.invalidate(cashuBalanceProvider);

      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'mint_${DateTime.now().millisecondsSinceEpoch}',
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
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Mint quote not paid or verification failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
          onChanged: (_) => _generateInvoice(),
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
                child: _isGenerating
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _generatedInvoice.isNotEmpty
                        ? QrImageView(
                            data: _generatedInvoice,
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
                style:
                    AppTypography.titleSmall.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Pay with any Lightning wallet to mint spendable ecash',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (_generatedInvoice.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: SelectableText(
                    _generatedInvoice.length > 36
                        ? '${_generatedInvoice.substring(0, 32)}...'
                        : _generatedInvoice,
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
                            ClipboardData(text: _generatedInvoice));
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

        if (_quoteId != null)
          ElevatedButton.icon(
            onPressed: _isChecking ? null : _checkAndMint,
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Check Payment & Mint Ecash'),
          ),
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
