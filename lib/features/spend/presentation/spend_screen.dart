import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/spend/data/bills_service.dart';
import 'package:hanbova_app/features/spend/domain/bill_models.dart';

class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  bool _isLoadingBillers = false;

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
            // Sandbox Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_outlined,
                      color: Colors.amberAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SANDBOX UTILITIES: Real biller validation and quotes powered by DT One backend adapter.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Pay Bills in ${spendCountry.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a utility or digital service to pay with Bitcoin.',
              style: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 13),
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

  void _showPaymentFormSheet(Biller biller) {
    final accountController =
        TextEditingController(text: biller.accountReferenceExample);
    final amountController = TextEditingController(text: '500');
    bool isValidating = false;
    CustomerValidation? validation;
    BillQuote? quote;
    bool isQuoting = false;

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
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Sats:',
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
                    ),
                    const SizedBox(height: 16),
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
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.of(ctx).pop();
                              try {
                                final serviceApi =
                                    ref.read(billsServiceProvider);
                                final tx = await serviceApi.payBill(
                                  quoteId: quote!.quoteId,
                                  customerAccount: quote!.customerAccount,
                                );
                                if (mounted) {
                                  _showReceiptDialog(tx);
                                }
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Payment error: $e')),
                                );
                              }
                            },
                            child: const Text('Pay with Bitcoin',
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

  void _showReceiptDialog(BillTransaction tx) {
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
              Text('Receipt #: ${tx.receiptNumber ?? "N/A"}',
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
