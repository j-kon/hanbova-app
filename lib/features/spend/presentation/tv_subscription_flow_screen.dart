import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import 'payment_confirmation_sheet.dart';
import 'payment_result_sheets.dart';

class TvBouquet {
  final String id;
  final String providerName;
  final String name;
  final double fiatPrice;
  final String channelsCount;

  const TvBouquet({
    required this.id,
    required this.providerName,
    required this.name,
    required this.fiatPrice,
    required this.channelsCount,
  });
}

class TvSubscriptionFlowScreen extends ConsumerStatefulWidget {
  const TvSubscriptionFlowScreen({super.key});

  @override
  ConsumerState<TvSubscriptionFlowScreen> createState() =>
      _TvSubscriptionFlowScreenState();
}

class _TvSubscriptionFlowScreenState
    extends ConsumerState<TvSubscriptionFlowScreen> {
  String _selectedProvider = 'DSTV';
  late TextEditingController _smartcardController;
  TvBouquet? _selectedBouquet;

  final List<TvBouquet> _allBouquets = const [
    // DSTV
    TvBouquet(
        id: 'dstv-padi',
        providerName: 'DSTV',
        name: 'DStv Padi',
        fiatPrice: 3600.0,
        channelsCount: '45+ channels'),
    TvBouquet(
        id: 'dstv-yanga',
        providerName: 'DSTV',
        name: 'DStv Yanga',
        fiatPrice: 5100.0,
        channelsCount: '85+ channels'),
    TvBouquet(
        id: 'dstv-confam',
        providerName: 'DSTV',
        name: 'DStv Confam',
        fiatPrice: 9300.0,
        channelsCount: '105+ channels'),
    TvBouquet(
        id: 'dstv-compact',
        providerName: 'DSTV',
        name: 'DStv Compact',
        fiatPrice: 15700.0,
        channelsCount: '130+ channels (EPL included)'),
    TvBouquet(
        id: 'dstv-premium',
        providerName: 'DSTV',
        name: 'DStv Premium',
        fiatPrice: 37000.0,
        channelsCount: '160+ channels (All Sports & HD)'),

    // GOtv
    TvBouquet(
        id: 'gotv-smallie',
        providerName: 'GOtv',
        name: 'GOtv Smallie',
        fiatPrice: 1575.0,
        channelsCount: '35+ channels'),
    TvBouquet(
        id: 'gotv-jinja',
        providerName: 'GOtv',
        name: 'GOtv Jinja',
        fiatPrice: 3300.0,
        channelsCount: '45+ channels'),
    TvBouquet(
        id: 'gotv-max',
        providerName: 'GOtv',
        name: 'GOtv Max',
        fiatPrice: 7200.0,
        channelsCount: '75+ channels (La Liga & Serie A)'),
    TvBouquet(
        id: 'gotv-supa',
        providerName: 'GOtv',
        name: 'GOtv Supa Plus',
        fiatPrice: 15700.0,
        channelsCount: '80+ channels (Premier League)'),

    // StarTimes
    TvBouquet(
        id: 'star-nova',
        providerName: 'StarTimes',
        name: 'Nova Bouquet',
        fiatPrice: 1700.0,
        channelsCount: '30+ channels'),
    TvBouquet(
        id: 'star-basic',
        providerName: 'StarTimes',
        name: 'Basic Bouquet',
        fiatPrice: 3300.0,
        channelsCount: '50+ channels'),
    TvBouquet(
        id: 'star-classic',
        providerName: 'StarTimes',
        name: 'Classic Bouquet',
        fiatPrice: 5000.0,
        channelsCount: '70+ channels'),
  ];

  @override
  void initState() {
    super.initState();
    _smartcardController = TextEditingController(text: '1029384756');
    _selectedBouquet = _allBouquets.firstWhere((b) => b.id == 'dstv-compact');
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    super.dispose();
  }

  Future<void> _proceedToConfirmation() async {
    if (_selectedBouquet == null) return;
    final bouquet = _selectedBouquet!;
    final market = ref.read(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final currency = ref.read(currencyProvider);
    final amountSats = currency.fiatToSats(bouquet.fiatPrice);

    final confirmed = await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm TV Subscription',
      billerName: bouquet.providerName,
      accountReference: _smartcardController.text.trim(),
      accountHolderName: 'Verified Account (Adekunle J.)',
      planOrBouquetName: bouquet.name,
      fiatAmount: bouquet.fiatPrice,
      fiatCurrency: 'NGN',
      amountSats: amountSats,
      feeSats: 50,
      serviceIcon: Icons.tv_rounded,
      onConfirm: () async {
        final tx = TransactionModel(
          id: 'tx-tv-${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.tv,
          status: TransactionStatus.completed,
          amountSats: amountSats,
          recipientOrSender: bouquet.providerName,
          description: '${bouquet.providerName} - ${bouquet.name}',
          createdAt: DateTime.now(),
          fiatAmount: bouquet.fiatPrice,
          fiatCurrency: 'NGN',
          feeSats: 50,
          billerName: bouquet.providerName,
          accountReference: _smartcardController.text.trim(),
          planName: bouquet.name,
          paymentMethod: 'Bitcoin Wallet',
          spendCountry: countryCode,
          receiptReference: 'TV-${DateTime.now().millisecondsSinceEpoch}',
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);
      },
    );

    if (confirmed == true && mounted) {
      final tx = TransactionModel(
        id: 'tx-tv-recent',
        type: TransactionType.tv,
        status: TransactionStatus.completed,
        amountSats: amountSats,
        recipientOrSender: bouquet.providerName,
        description: '${bouquet.providerName} - ${bouquet.name}',
        createdAt: DateTime.now(),
        fiatAmount: bouquet.fiatPrice,
        fiatCurrency: 'NGN',
        feeSats: 50,
        billerName: bouquet.providerName,
        accountReference: _smartcardController.text.trim(),
        planName: bouquet.name,
        paymentMethod: 'Bitcoin Wallet',
        spendCountry: countryCode,
        receiptReference: 'TV-REC-${DateTime.now().millisecondsSinceEpoch}',
      );

      await PaymentSuccessSheet.show(
        context,
        transaction: tx,
        billerName: bouquet.providerName,
        accountReference: _smartcardController.text.trim(),
        fiatAmount: bouquet.fiatPrice,
        fiatCurrency: 'NGN',
        amountSats: amountSats,
        onDone: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);
    final bouquets = _allBouquets
        .where((b) =>
            b.providerName.toUpperCase() == _selectedProvider.toUpperCase())
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'TV Subscription',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/activity?query=TV'),
            icon: Icon(Icons.history_rounded, size: 18, color: colors.primary),
            label: Text(
              'History',
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Selector
            Text(
              'Select Provider',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['DSTV', 'GOtv', 'StarTimes', 'Showmax'].map((p) {
                final isSelected = _selectedProvider == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProvider = p;
                        _selectedBouquet = _allBouquets.firstWhere(
                          (b) =>
                              b.providerName.toUpperCase() == p.toUpperCase(),
                          orElse: () => _allBouquets.first,
                        );
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.charcoal
                              : colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Smartcard Number
            Text(
              'Smartcard / IUC Number',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smartcardController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceCard,
                prefixIcon: Icon(Icons.credit_card_rounded,
                    color: colors.textSecondary, size: 20),
                hintText: 'Enter 10-digit smartcard number',
                hintStyle: TextStyle(color: colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouquet Selection
            Text(
              'Select Bouquet / Package',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...bouquets.map((b) {
              final isSelected = _selectedBouquet?.id == b.id;
              final sats = currency.fiatToSats(b.fiatPrice);

              return GestureDetector(
                onTap: () => setState(() => _selectedBouquet = b),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.tv, color: colors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.channelsCount,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${NumberFormat('#,##0').format(b.fiatPrice)}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '≈ ${Formatters.formatSats(sats)}',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: colors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedBouquet != null ? _proceedToConfirmation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
