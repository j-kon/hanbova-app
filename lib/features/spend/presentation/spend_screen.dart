import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/spend/data/bills_service.dart';
import 'package:hanbova_app/features/spend/domain/bill_models.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

class SavedBillerItem {
  final String id;
  final String billerId;
  final String billerName;
  final String accountReference;
  final BillServiceType serviceType;
  final String countryCode;

  const SavedBillerItem({
    required this.id,
    required this.billerId,
    required this.billerName,
    required this.accountReference,
    required this.serviceType,
    required this.countryCode,
  });
}

class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  bool _isLoadingBillers = false;

  // Local state for Saved Billers / Pay Again
  final List<SavedBillerItem> _savedBillers = [
    const SavedBillerItem(
      id: 'sb-1',
      billerId: 'ke-kplc-prepaid',
      billerName: 'Kenya Power (KPLC Prepaid)',
      accountReference: '37189201948',
      serviceType: BillServiceType.electricity,
      countryCode: 'KE',
    ),
    const SavedBillerItem(
      id: 'sb-2',
      billerId: 'ke-safaricom-airtime',
      billerName: 'Safaricom Airtime',
      accountReference: '+254 712 345 678',
      serviceType: BillServiceType.airtime,
      countryCode: 'KE',
    ),
    const SavedBillerItem(
      id: 'sb-3',
      billerId: 'ng-mtn-data',
      billerName: 'MTN Data Bundles',
      accountReference: '+234 803 123 4567',
      serviceType: BillServiceType.data,
      countryCode: 'NG',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;
    final caps = market.capabilities;

    final List<BillServiceType> activeServices = [
      if (caps.airtime) BillServiceType.airtime,
      if (caps.data) BillServiceType.data,
      if (caps.electricity) BillServiceType.electricity,
      if (caps.water) BillServiceType.water,
      if (caps.tv) BillServiceType.tv,
      if (caps.internet) BillServiceType.internet,
    ];

    final relevantSavedBillers = _savedBillers
        .where((b) =>
            b.countryCode.toUpperCase() == spendCountry.code.toUpperCase())
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Everyday Spend & Bills',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${spendCountry.flagEmoji} ${spendCountry.code}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe Simulation Environment Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SIMULATION ENVIRONMENT: Everyday utility bill payments and top-ups operate in safe pilot mode.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Billers / Pay Again (if any)
            if (relevantSavedBillers.isNotEmpty) ...[
              const Text(
                'Recent & Saved Billers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: relevantSavedBillers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final sb = relevantSavedBillers[idx];
                    return InkWell(
                      onTap: () => _onSavedBillerTapped(sb),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(sb.serviceType.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    sb.billerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sb.accountReference,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to Pay Again',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'Pay Bills in ${spendCountry.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a utility or digital service to pay with Bitcoin.',
              style:
                  TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Service Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: activeServices.length,
              itemBuilder: (context, index) {
                final service = activeServices[index];
                return InkWell(
                  onTap: () => _onServiceSelected(service),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(service.icon,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 10),
                        Text(
                          service.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (_isLoadingBillers) ...[
              const SizedBox(height: 30),
              const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onSavedBillerTapped(SavedBillerItem sb) async {
    setState(() => _isLoadingBillers = true);
    final market = ref.read(marketProvider);
    final serviceApi = ref.read(billsServiceProvider);
    final billers = await serviceApi.getBillers(market.spendCountry,
        service: sb.serviceType);
    if (mounted) {
      setState(() => _isLoadingBillers = false);
      final found = billers.firstWhere(
        (b) => b.id == sb.billerId || b.name == sb.billerName,
        orElse: () => Biller(
          id: sb.billerId,
          name: sb.billerName,
          serviceType: sb.serviceType,
          country: sb.countryCode,
          accountReferenceLabel: 'Account Number',
          accountReferenceExample: sb.accountReference,
        ),
      );
      _showPaymentFormSheet(found, initialAccount: sb.accountReference);
    }
  }

  Future<void> _onServiceSelected(BillServiceType service) async {
    setState(() {
      _isLoadingBillers = true;
    });

    final market = ref.read(marketProvider);
    final serviceApi = ref.read(billsServiceProvider);
    final billers =
        await serviceApi.getBillers(market.spendCountry, service: service);

    if (mounted) {
      setState(() {
        _isLoadingBillers = false;
      });

      _showBillerPickerSheet(service, billers);
    }
  }

  void _showBillerPickerSheet(BillServiceType service, List<Biller> billers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(service.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Select ${service.title} Provider',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (billers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No providers available for this service in the selected country.',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: billers.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.darkBorder,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final biller = billers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          biller.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Requires ${biller.accountReferenceLabel} (e.g. ${biller.accountReferenceExample})',
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.darkTextSecondary,
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showPaymentFormSheet(biller);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentFormSheet(Biller biller, {String? initialAccount}) {
    final accountController = TextEditingController(
      text: initialAccount ?? biller.accountReferenceExample,
    );
    final amountController = TextEditingController(text: '500');
    bool isValidating = false;
    CustomerValidation? validation;
    BillQuote? quote;
    bool isQuoting = false;
    bool saveBillerForFuture = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final market = ref.read(marketProvider);
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    biller.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Reference Input
                  Text(
                    biller.accountReferenceLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accountController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkSurfaceCard,
                      hintText: biller.accountReferenceExample,
                      hintStyle: const TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.darkBorder),
                      ),
                      suffixIcon: IconButton(
                        icon: isValidating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.check, color: AppColors.primary),
                        onPressed: () async {
                          setModalState(() => isValidating = true);
                          final serviceApi = ref.read(billsServiceProvider);
                          final res = await serviceApi.validateCustomer(
                              biller.id, accountController.text);
                          setModalState(() {
                            validation = res;
                            isValidating = false;
                          });
                        },
                      ),
                    ),
                  ),

                  if (validation != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          validation!.isValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: validation!.isValid
                              ? AppColors.success
                              : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          validation!.customerName ?? 'Validated',
                          style: TextStyle(
                            color: validation!.isValid
                                ? AppColors.success
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Amount in Fiat
                  Text(
                    'Amount (${market.displayCurrency.code})',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkSurfaceCard,
                      hintText: '500',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.darkBorder),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quote Box
                  if (quote != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Bitcoin Sats:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                '${quote!.amountSats} sats',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Network / Settlement Fee:',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              Text(
                                '${quote!.feeSats} sats',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Save Biller Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: saveBillerForFuture,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setModalState(
                              () => saveBillerForFuture = v ?? true),
                        ),
                        const Text(
                          'Save biller for quick payments',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      if (quote == null)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isQuoting
                                ? null
                                : () async {
                                    setModalState(() => isQuoting = true);
                                    try {
                                      final serviceApi =
                                          ref.read(billsServiceProvider);
                                      final amt = double.tryParse(
                                              amountController.text) ??
                                          500.0;
                                      final q = await serviceApi.createQuote(
                                        billerId: biller.id,
                                        amountFiat: amt,
                                        customerAccount: accountController.text,
                                      );
                                      setModalState(() {
                                        quote = q;
                                        isQuoting = false;
                                      });
                                    } catch (e) {
                                      setModalState(() => isQuoting = false);
                                    }
                                  },
                            child: isQuoting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text('Get Quote',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _executePaymentFlow(
                              biller: biller,
                              quote: quote!,
                              saveBiller: saveBillerForFuture,
                            ),
                            child: const Text('Confirm & Pay with Bitcoin',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executePaymentFlow({
    required Biller biller,
    required BillQuote quote,
    required bool saveBiller,
  }) async {
    Navigator.of(context).pop(); // Close form sheet

    // Show processing / uncertain modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 20),
                Text(
                  'Processing Utility Settlement',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Checking payment status — please do not attempt duplicate payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.darkTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final serviceApi = ref.read(billsServiceProvider);
      final tx = await serviceApi.payBill(
        quoteId: quote.quoteId,
        customerAccount: quote.customerAccount,
      );

      // Record to unified activity timeline
      TransactionType txType;
      switch (biller.serviceType) {
        case BillServiceType.airtime:
          txType = TransactionType.airtime;
          break;
        case BillServiceType.data:
          txType = TransactionType.data;
          break;
        case BillServiceType.electricity:
          txType = TransactionType.electricity;
          break;
        case BillServiceType.water:
          txType = TransactionType.water;
          break;
        case BillServiceType.tv:
          txType = TransactionType.tv;
          break;
        case BillServiceType.internet:
          txType = TransactionType.internet;
          break;
      }

      ref.read(transactionsProvider.notifier).recordBillPayment(
            id: tx.id,
            type: txType,
            billerName: biller.name,
            accountReference: tx.customerAccount,
            amountSats: tx.amountSats,
            fiatAmount: quote.amountFiat,
            fiatCurrency: quote.currency,
            feeSats: quote.feeSats,
            tokenOrPin: tx.tokenCode,
            receiptReference: tx.receiptNumber,
            spendCountry: biller.countryCode,
          );

      if (saveBiller) {
        setState(() {
          final alreadySaved = _savedBillers.any((s) =>
              s.billerId == biller.id &&
              s.accountReference == tx.customerAccount);
          if (!alreadySaved) {
            _savedBillers.insert(
              0,
              SavedBillerItem(
                id: 'sb-${DateTime.now().millisecondsSinceEpoch}',
                billerId: biller.id,
                billerName: biller.name,
                accountReference: tx.customerAccount,
                serviceType: biller.serviceType,
                countryCode: biller.countryCode,
              ),
            );
          }
        });
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close processing modal
        _showReceiptDialog(tx, biller);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close processing modal
        _showUncertainOrErrorState(e.toString());
      }
    }
  }

  void _showUncertainOrErrorState(String error) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text(
                'Checking Payment Status',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checking payment status — please do not attempt duplicate payment.',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment is being verified with the network operator. You can monitor the transaction timeline in your Activity tab.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showReceiptDialog(BillTransaction tx, Biller biller) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
              SizedBox(width: 8),
              Text(
                'Payment Receipt',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${tx.status.toUpperCase()}',
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Biller: ${biller.name}',
                  style: const TextStyle(color: Colors.white70)),
              Text(
                  'Receipt #: ${tx.receiptNumber ?? "REC-${tx.id.substring(0, 8)}"}',
                  style: const TextStyle(color: Colors.white70)),
              Text('Account: ${tx.customerAccount}',
                  style: const TextStyle(color: Colors.white70)),
              Text('Paid: ${tx.amountSats} sats',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              if (tx.tokenCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ Electricity Meter Recharge Token',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tx.tokenCode!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: AppColors.primary, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: tx.tokenCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Token copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
