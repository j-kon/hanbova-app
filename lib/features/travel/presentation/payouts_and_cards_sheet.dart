import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'package:hanbova_app/features/travel/data/esim_service.dart';
import 'package:hanbova_app/features/travel/domain/esim_models.dart';

class PayoutsAndCardsSheet {
  static void showPayouts(BuildContext context, String country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PayoutsModalContent(country: country),
    );
  }

  static void showCards(BuildContext context, String country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CardsModalContent(country: country),
    );
  }
}

class _PayoutsModalContent extends ConsumerStatefulWidget {
  final String country;
  const _PayoutsModalContent({required this.country});

  @override
  ConsumerState<_PayoutsModalContent> createState() =>
      _PayoutsModalContentState();
}

class _PayoutsModalContentState extends ConsumerState<_PayoutsModalContent> {
  List<PayoutCorridor> _corridors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCorridors();
  }

  Future<void> _loadCorridors() async {
    final service = ref.read(travelServiceProvider);
    final corridors = await service.getPayoutCorridors(widget.country);
    if (mounted) {
      setState(() {
        _corridors = corridors;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Cash Payouts',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Direct Rails',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Convert Bitcoin instantly to local mobile money and domestic bank accounts.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Simulation environment disclaimer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: colors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULATION ENVIRONMENT: Cash-out rails operate in safe simulation mode.',
                    style: TextStyle(color: colors.textPrimary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: CircularProgressIndicator(color: colors.primary),
              ),
            )
          else if (_corridors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No payout corridors available for this region.',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _corridors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final corr = _corridors[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            corr.isMobileMoney
                                ? Icons.phone_android
                                : Icons.account_balance,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                corr.name,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rail: ${corr.type.toUpperCase()} • Currency: ${corr.currency}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showPayoutForm(context, corr),
                          child: const Text('Send',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showPayoutForm(BuildContext context, PayoutCorridor corr) {
    final colors = context.colors;
    final destinationController = TextEditingController();
    final amountController = TextEditingController(text: '1000');

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cash Out to ${corr.name}',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  corr.isMobileMoney
                      ? 'Mobile Number / Account'
                      : 'Bank Account Number',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: destinationController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  hintText:
                      corr.isMobileMoney ? '+254 700 000 000' : '0123456789',
                  hintStyle: TextStyle(color: colors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Amount (${corr.currency})',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  hintText: '1000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final dest = destinationController.text.trim();
                    final amt =
                        double.tryParse(amountController.text) ?? 1000.0;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    Navigator.pop(context);

                    await ref.read(transactionsProvider.notifier).recordPayout(
                          id: 'payout-${DateTime.now().millisecondsSinceEpoch}',
                          destination:
                              dest.isNotEmpty ? dest : 'Recipient Account',
                          corridorName: corr.name,
                          amountSats: 2500,
                          fiatAmount: amt,
                          fiatCurrency: corr.currency,
                          feeSats: 25,
                          isMobileMoney: corr.isMobileMoney,
                        );

                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              'Cash payout of ${corr.currency} $amt initiated!')),
                    );
                  },
                  child: const Text('Confirm Cash Out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardsModalContent extends ConsumerWidget {
  final String country;
  const _CardsModalContent({required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Virtual Dollar Cards',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Visa / Mastercard',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Spend globally online with instant USD virtual cards funded from Bitcoin.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Virtual Card Visual Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B4E), Color(0xFF16102B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HANBOVA GLOBAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.contactless, color: Colors.white70, size: 22),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  '•••• •••• •••• 4829',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('EXP: 11/28',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('VISA DEBIT',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Simulation Note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: colors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULATION ENVIRONMENT: Virtual card issuance operates in safe simulation mode.',
                    style: TextStyle(color: colors.textPrimary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Virtual card issued! View in your Travel Cards.'),
                  ),
                );
              },
              child: const Text(
                'Issue Virtual Dollar Card',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
