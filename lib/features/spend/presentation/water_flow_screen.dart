import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import 'payment_confirmation_sheet.dart';
import 'payment_result_sheets.dart';

class WaterProviderOption {
  final String id;
  final String name;
  final String countryCode;
  final Color brandColor;

  const WaterProviderOption({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.brandColor,
  });
}

class WaterFlowScreen extends ConsumerStatefulWidget {
  const WaterFlowScreen({super.key});

  @override
  ConsumerState<WaterFlowScreen> createState() => _WaterFlowScreenState();
}

class _WaterFlowScreenState extends ConsumerState<WaterFlowScreen> {
  final _accountController = TextEditingController(text: '7829104829');
  final _amountController = TextEditingController(text: '5000');
  String _selectedProviderId = 'ng-lwc';
  final int _selectedSavedIndex = 0; // Pre-select first saved account

  final List<Map<String, dynamic>> _savedWaterAccounts = [
    {
      'title': 'Home Water Supply',
      'providerName': 'Lagos Water Corporation (LWC)',
      'providerId': 'ng-lwc',
      'accountNumber': '••••4921',
      'fullAccount': '7829104829',
      'fiatAmount': 5000.0,
      'currency': 'NGN',
      'color': const Color(0xFF60A5FA),
    },
    {
      'title': 'Family Home Abuja',
      'providerName': 'FCT Water Board',
      'providerId': 'ng-fct-water',
      'accountNumber': '••••8102',
      'fullAccount': '3029182736',
      'fiatAmount': 4200.0,
      'currency': 'NGN',
      'color': const Color(0xFF38BDF8),
    },
  ];

  final Map<String, List<WaterProviderOption>> _providers = {
    'NG': const [
      WaterProviderOption(
        id: 'ng-lwc',
        name: 'Lagos Water Corporation (LWC)',
        countryCode: 'NG',
        brandColor: Color(0xFF60A5FA),
      ),
      WaterProviderOption(
        id: 'ng-fct-water',
        name: 'FCT Water Board (Abuja)',
        countryCode: 'NG',
        brandColor: Color(0xFF38BDF8),
      ),
      WaterProviderOption(
        id: 'ng-rivers-water',
        name: 'Rivers State Water Board',
        countryCode: 'NG',
        brandColor: Color(0xFF10B981),
      ),
    ],
    'KE': const [
      WaterProviderOption(
        id: 'ke-ncwsc',
        name: 'Nairobi Water (NCWSC)',
        countryCode: 'KE',
        brandColor: Color(0xFF008542),
      ),
      WaterProviderOption(
        id: 'ke-mowassco',
        name: 'Mombasa Water (MOWASSCO)',
        countryCode: 'KE',
        brandColor: Color(0xFF0284C7),
      ),
    ],
    'GH': const [
      WaterProviderOption(
        id: 'gh-gwc',
        name: 'Ghana Water Company (GWCL)',
        countryCode: 'GH',
        brandColor: Color(0xFF0284C7),
      ),
    ],
  };

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int _calculateSats(double fiatAmount, String countryCode) {
    final rate = _getExchangeRate(countryCode);
    if (rate <= 0) return 500;
    final btc = fiatAmount / rate;
    return (btc * 100000000).round().clamp(10, 50000000);
  }

  double _getExchangeRate(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'KE':
        return 12500000.0;
      case 'GH':
        return 1450000.0;
      case 'NG':
      default:
        return 145000000.0;
    }
  }

  String _getCurrencySymbol(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'KE':
        return 'KSh';
      case 'GH':
        return 'GH₵';
      case 'NG':
      default:
        return '₦';
    }
  }

  void _handlePaySaved(Map<String, dynamic> account, String countryCode) {
    final fiatAmount = account['fiatAmount'] as double;
    final sats = _calculateSats(fiatAmount, countryCode);
    final currency = account['currency'] as String;
    final providerName = account['providerName'] as String;
    final accountNumber = account['accountNumber'] as String;

    _showConfirmationAndPay(
      billerName: providerName,
      accountRef: accountNumber,
      fiatAmount: fiatAmount,
      fiatCurrency: currency,
      sats: sats,
      countryCode: countryCode,
    );
  }

  void _handlePayNew(String countryCode) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final account = _accountController.text.trim();
    if (account.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid water meter / customer account ID'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final providerList = _providers[countryCode] ?? _providers['NG']!;
    final provider = providerList.firstWhere(
      (p) => p.id == _selectedProviderId,
      orElse: () => providerList.first,
    );

    final sats = _calculateSats(amount, countryCode);

    _showConfirmationAndPay(
      billerName: provider.name,
      accountRef: account,
      fiatAmount: amount,
      fiatCurrency:
          countryCode == 'KE' ? 'KES' : (countryCode == 'GH' ? 'GHS' : 'NGN'),
      sats: sats,
      countryCode: countryCode,
    );
  }

  Future<void> _showConfirmationAndPay({
    required String billerName,
    required String accountRef,
    required double fiatAmount,
    required String fiatCurrency,
    required int sats,
    required String countryCode,
  }) async {
    await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Water Bill Payment',
      billerName: billerName,
      accountReference: accountRef,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      amountSats: sats,
      serviceIcon: Icons.water_drop_rounded,
      onConfirm: () async {
        await Future.delayed(const Duration(milliseconds: 600));

        final tx = TransactionModel(
          id: 'wtr_${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.water,
          status: TransactionStatus.completed,
          amountSats: sats,
          fiatAmount: fiatAmount,
          fiatCurrency: fiatCurrency,
          recipientOrSender: billerName,
          billerName: billerName,
          accountReference: accountRef,
          receiptReference:
              'WTR-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          spendCountry: countryCode,
          description: '$billerName Water Bill ($accountRef)',
          createdAt: DateTime.now(),
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);

        if (mounted) {
          PaymentSuccessSheet.show(
            context,
            transaction: tx,
            billerName: billerName,
            accountReference: accountRef,
            fiatAmount: fiatAmount,
            fiatCurrency: fiatCurrency,
            amountSats: sats,
            serviceTitle: 'Water Bill Paid',
            onDone: () => Navigator.of(context).pop(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final providerList = _providers[countryCode] ?? _providers['NG']!;
    final currencySymbol = _getCurrencySymbol(countryCode);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Water Utilities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/activity?query=Water'),
            icon: const Icon(Icons.history_rounded,
                size: 18, color: AppColors.primary),
            label: const Text(
              'History',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repeat-first: Saved Accounts
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Water Accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Repeat Pay',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._savedWaterAccounts.asMap().entries.map((entry) {
              final idx = entry.key;
              final acc = entry.value;
              final isSelected = _selectedSavedIndex == idx;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.darkBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (acc['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.water_drop_rounded,
                          color: acc['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${acc['providerName']} • ${acc['accountNumber']}',
                            style: const TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$currencySymbol ${Formatters.formatSatsNumber((acc['fiatAmount'] as double).round())}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePaySaved(acc, countryCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 16),

            // Form: Pay Another Account
            const Text(
              'Pay Another Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select water utility provider and enter customer account number',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),

            // Provider Selection
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: providerList.map((p) {
                  final isSelected = p.id == _selectedProviderId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedProviderId = p.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p.brandColor.withValues(alpha: 0.15)
                            : AppColors.darkCardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? p.brandColor : AppColors.darkBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.water_drop_rounded,
                              size: 16,
                              color:
                                  isSelected ? p.brandColor : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            p.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Account Number Input
            const Text(
              'Customer Account ID / Meter Number',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. 7829104829',
                hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkCardBackground,
                prefixIcon: const Icon(Icons.water_damage_outlined,
                    color: AppColors.primary, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            Text(
              'Amount ($currencySymbol)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '$currencySymbol ',
                prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.darkCardBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Live Sats preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated Bitcoin cost: ${Formatters.formatSats(_calculateSats(double.tryParse(_amountController.text.trim()) ?? 0, countryCode))}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pay Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handlePayNew(countryCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Pay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
