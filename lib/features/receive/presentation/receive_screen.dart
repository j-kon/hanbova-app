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

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amountController = TextEditingController(text: '10000');
  String _generatedInvoice = '';
  String? _quoteId;
  bool _isGenerating = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
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
    final currency = ref.watch(currencyProvider);
    final currentSats = int.tryParse(_amountController.text.trim()) ?? 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Receive Bitcoin'),
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
                    if (_generatedInvoice.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                                    content:
                                        Text('Invoice copied to clipboard')),
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
          ),
        ),
      ),
    );
  }
}
