import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amountController = TextEditingController(text: '10000');
  String _generatedInvoice = '';

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

  void _generateInvoice() {
    final sats = int.tryParse(_amountController.text.trim()) ?? 10000;
    setState(() {
      _generatedInvoice = 'lnbc${sats}u1pjhnbvareceive${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  void _simulateReceive() {
    final sats = int.tryParse(_amountController.text.trim()) ?? 10000;
    ref.read(walletStateProvider.notifier).creditBalance(sats);
    ref.read(transactionsProvider.notifier).addTransaction(
          TransactionModel(
            id: 'ln_recv_${DateTime.now().millisecondsSinceEpoch}',
            type: TransactionType.instantReceive,
            status: TransactionStatus.completed,
            amountSats: sats,
            recipientOrSender: 'Lightning Sender',
            description: 'Received via Lightning Invoice',
            createdAt: DateTime.now(),
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Received ${Formatters.formatSats(sats)} successfully!')),
    );
    context.go('/home');
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.mdRadius,
                      ),
                      child: QrImageView(
                        data: _generatedInvoice,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Lightning Invoice (BOLT11)',
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan with any Lightning or Hanbova wallet to pay',
                      style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            Clipboard.setData(ClipboardData(text: _generatedInvoice));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoice copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy invoice'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              ElevatedButton.icon(
                onPressed: _simulateReceive,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Simulate Incoming Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
