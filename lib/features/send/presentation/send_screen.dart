import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/lightning/lightning_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';

class SendScreen extends ConsumerStatefulWidget {
  final String? initialInvoice;
  final String? initialRecipient;

  const SendScreen({super.key, this.initialInvoice, this.initialRecipient});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _invoiceController;
  final _amountController = TextEditingController(text: '5000');
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _invoiceController = TextEditingController(
      text: widget.initialInvoice ?? widget.initialRecipient ?? '',
    );
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _payInstant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amountSats = int.tryParse(_amountController.text.trim()) ?? 1000;
    final invoice = _invoiceController.text.trim();

    try {
      final cashuWallet = ref.read(cashuWalletServiceProvider);
      int paidAmountSats = amountSats;
      int feeSats = 0;
      String? preimage;

      if (cashuWallet != null && invoice.toLowerCase().startsWith('lnbc')) {
        // Execute genuine NUT-05 ecash melt
        final quote = await cashuWallet.createMeltQuote(invoice);
        final meltResult = await cashuWallet.payMeltQuote(quote.quoteId);
        if (!meltResult.isPaid) {
          throw StateError('Melt payment could not be completed by the mint');
        }
        paidAmountSats = quote.amountSats;
        feeSats = quote.feeReserveSats;
        preimage = meltResult.preimage;
        ref.invalidate(cashuBalanceProvider);
      } else {
        final lightningService = ref.read(lightningServiceProvider);
        final result = await lightningService.payInvoice(bolt11: invoice);
        paidAmountSats = result.amountSats > 0 ? result.amountSats : amountSats;
        feeSats = result.feeSats;
        preimage = result.preimage;
      }

      ref.read(walletStateProvider.notifier).deductBalance(paidAmountSats + feeSats);
      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'ln_pay_${DateTime.now().millisecondsSinceEpoch}',
              type: TransactionType.instantSend,
              status: TransactionStatus.completed,
              amountSats: paidAmountSats,
              recipientOrSender: invoice.length > 20 ? '${invoice.substring(0, 16)}...' : invoice,
              description: 'Lightning Payment (fee: $feeSats sats${preimage != null && preimage.isNotEmpty ? ", preimage: ${preimage.substring(0, (preimage.length >= 8 ? 8 : preimage.length))}..." : ""})',
              createdAt: DateTime.now(),
            ),
          );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        title: const Text('Instant Send'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isSuccess
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.amber, size: 40),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Payment Sent!',
                      style: AppTypography.headline.copyWith(color: colors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Lightning payment settled instantly and confirmed.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 24),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Instant payments settle immediately on the Lightning Network and are final.',
                                style: AppTypography.bodySmall.copyWith(color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      TextFormField(
                        controller: _invoiceController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Lightning Invoice or Address',
                          hintText: 'Paste lnbc1... or @username',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () => context.push('/scan'),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter invoice or address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Amount (sats)',
                          suffixText: currency.format(currentSats),
                          prefixIcon: const Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _payInstant,
                        icon: const Icon(Icons.bolt, size: 18),
                        label: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Pay Instantly'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
