import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/consumer_error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';

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
  bool _isLoading = false;
  bool _isSuccess = false;
  MeltQuoteResult? _activeQuote;

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
    super.dispose();
  }

  Future<void> _fetchQuote() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _activeQuote = null;
    });

    final invoice = _invoiceController.text.trim();

    try {
      final cashuWallet = ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError(
            'Cashu wallet is not initialized. Please ensure your wallet seed is configured.');
      }
      if (!invoice.toLowerCase().startsWith('lnbc')) {
        throw ArgumentError(
            'Please enter a valid BOLT11 Lightning invoice (starting with lnbc).');
      }

      // Execute genuine NUT-05 ecash melt quote through CDK
      final quote = await cashuWallet.createMeltQuote(invoice);
      if (quote.amountSats <= 0) {
        throw StateError(
            'Amountless Lightning invoices are not supported. Please use an invoice with a specified amount.');
      }

      final config = ref.read(activeNetworkConfigProvider);
      if (quote.amountSats > config.maxSendSats) {
        throw StateError(
            'Invoice amount of ${quote.amountSats} sats exceeds maximum single send limit of ${config.maxSendSats} sats for ${config.displayName}.');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeQuote = quote;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final friendlyMessage = ConsumerErrorTranslator.translate(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _executePayment() async {
    if (_isLoading || _activeQuote == null) return;

    setState(() => _isLoading = true);
    final quote = _activeQuote!;
    final invoice = _invoiceController.text.trim();

    try {
      final cashuWallet = ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError('Cashu wallet is not initialized.');
      }

      final meltResult = await cashuWallet.payMeltQuote(quote.quoteId);
      if (!meltResult.isPaid) {
        throw StateError('Melt payment could not be completed by the mint');
      }
      final paidAmountSats = quote.amountSats;
      final feeSats = quote.feeReserveSats;
      final preimage = meltResult.preimage;
      ref.invalidate(cashuBalanceProvider);

      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'ln_pay_${DateTime.now().millisecondsSinceEpoch}',
              type: TransactionType.instantSend,
              status: TransactionStatus.completed,
              amountSats: paidAmountSats,
              recipientOrSender: invoice.length > 20
                  ? '${invoice.substring(0, 16)}...'
                  : invoice,
              description:
                  'Lightning Payment (fee: $feeSats sats${preimage != null && preimage.isNotEmpty ? ", preimage: ${preimage.substring(0, (preimage.length >= 8 ? 8 : preimage.length))}..." : ""})',
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
      final friendlyMessage = ConsumerErrorTranslator.translate(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            ? _buildSuccessView()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt,
                                color: Colors.amber, size: 24),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Instant payments settle immediately on the Lightning Network and are final.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _invoiceController,
                        maxLines: 3,
                        enabled: _activeQuote == null && !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Lightning Invoice',
                          hintText:
                              'Paste a BOLT11 invoice starting with lnbc...',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () => context.push('/scan'),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a Lightning invoice';
                          }
                          if (!val.trim().toLowerCase().startsWith('lnbc')) {
                            return 'Invoice must start with lnbc';
                          }
                          return null;
                        },
                      ),
                      if (_activeQuote != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildQuoteConfirmationCard(_activeQuote!),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (_activeQuote == null)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _fetchQuote,
                          icon: const Icon(Icons.bolt, size: 18),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Review Invoice & Fees'),
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _executePayment,
                          icon: const Icon(Icons.check, size: 18),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Confirm & Pay Instantly'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _activeQuote = null;
                                  });
                                },
                          child: const Text('Change Invoice'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuoteConfirmationCard(MeltQuoteResult quote) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoice Amount',
                  style: AppTypography.bodySmall
                      .copyWith(color: colors.textSecondary)),
              Text(
                '${Formatters.formatSats(quote.amountSats)} (${currency.format(quote.amountSats)})',
                style: AppTypography.titleSmall
                    .copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fee Reserve',
                  style: AppTypography.bodySmall
                      .copyWith(color: colors.textSecondary)),
              Text(
                '${Formatters.formatSats(quote.feeReserveSats)} (${currency.format(quote.feeReserveSats)})',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          Divider(color: colors.divider, height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maximum Total',
                  style: AppTypography.titleSmall
                      .copyWith(color: colors.textPrimary)),
              Text(
                Formatters.formatSats(quote.amountSats + quote.feeReserveSats),
                style: AppTypography.headline
                    .copyWith(color: Colors.amber, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
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
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
