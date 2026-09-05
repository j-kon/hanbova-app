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

class InternetProviderOption {
  final String id;
  final String name;
  final String countryCode;
  final Color brandColor;

  const InternetProviderOption({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.brandColor,
  });
}

class InternetFlowScreen extends ConsumerStatefulWidget {
  const InternetFlowScreen({super.key});

  @override
  ConsumerState<InternetFlowScreen> createState() => _InternetFlowScreenState();
}

class _InternetFlowScreenState extends ConsumerState<InternetFlowScreen> {
  final _accountController = TextEditingController(text: '0192837465');
  final _amountController = TextEditingController(text: '15000');
  String _selectedProviderId = 'ng-spectranet';
  final int _selectedSavedIndex = 0; // Pre-select first saved account

  final List<Map<String, dynamic>> _savedInternetAccounts = [
    {
      'title': 'Home Wi-Fi',
      'providerName': 'Spectranet 4G LTE',
      'providerId': 'ng-spectranet',
      'accountNumber': '••••3819',
      'fullAccount': '0192837465',
      'planName': 'Unlimited Mega 50 Mbps',
      'fiatAmount': 15000.0,
      'currency': 'NGN',
      'color': const Color(0xFF38BDF8),
    },
    {
      'title': 'Office Starlink',
      'providerName': 'Starlink Residential',
      'providerId': 'ng-starlink',
      'accountNumber': '••••9021',
      'fullAccount': '8901234567',
      'planName': 'Standard Unlimited',
      'fiatAmount': 38000.0,
      'currency': 'NGN',
      'color': const Color(0xFFA78BFA),
    },
  ];

  final Map<String, List<InternetProviderOption>> _providers = {
    'NG': const [
      InternetProviderOption(
        id: 'ng-spectranet',
        name: 'Spectranet',
        countryCode: 'NG',
        brandColor: Color(0xFF38BDF8),
      ),
      InternetProviderOption(
        id: 'ng-smile',
        name: 'Smile Communications',
        countryCode: 'NG',
        brandColor: Color(0xFFEC4899),
      ),
      InternetProviderOption(
        id: 'ng-ipnx',
        name: 'ipNX Fibre',
        countryCode: 'NG',
        brandColor: Color(0xFF10B981),
      ),
      InternetProviderOption(
        id: 'ng-starlink',
        name: 'Starlink',
        countryCode: 'NG',
        brandColor: Color(0xFFA78BFA),
      ),
    ],
    'KE': const [
      InternetProviderOption(
        id: 'ke-safaricom-home',
        name: 'Safaricom Home Fibre',
        countryCode: 'KE',
        brandColor: Color(0xFF008542),
      ),
      InternetProviderOption(
        id: 'ke-zuku',
        name: 'Zuku Fiber',
        countryCode: 'KE',
        brandColor: Color(0xFFF59E0B),
      ),
    ],
    'GH': const [
      InternetProviderOption(
        id: 'gh-telecel-broadband',
        name: 'Telecel Broadband',
        countryCode: 'GH',
        brandColor: Color(0xFFE60000),
      ),
      InternetProviderOption(
        id: 'gh-mtn-fibre',
        name: 'MTN FibreBroadband',
        countryCode: 'GH',
        brandColor: Color(0xFFFFCC00),
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
    if (rate <= 0) return 1000;
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
    final planName = account['planName'] as String;

    _showConfirmationAndPay(
      billerName: providerName,
      accountRef: accountNumber,
      planName: planName,
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
          content: Text('Please enter a valid internet account/customer ID'),
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
      planName: 'Internet Subscription Renewal',
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
    required String planName,
    required double fiatAmount,
    required String fiatCurrency,
    required int sats,
    required String countryCode,
  }) async {
    await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Internet Payment',
      billerName: billerName,
      accountReference: accountRef,
      planOrBouquetName: planName,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      amountSats: sats,
      serviceIcon: Icons.router_rounded,
      onConfirm: () async {
        await Future.delayed(const Duration(milliseconds: 600));

        final tx = TransactionModel(
          id: 'int_${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.internet,
          status: TransactionStatus.completed,
          amountSats: sats,
          fiatAmount: fiatAmount,
          fiatCurrency: fiatCurrency,
          recipientOrSender: billerName,
          billerName: billerName,
          accountReference: accountRef,
          planName: planName,
          receiptReference:
              'INT-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          spendCountry: countryCode,
          description: '$billerName Internet Renewal ($accountRef)',
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
            serviceTitle: 'Internet Subscription Renewed',
            onDone: () => Navigator.of(context).pop(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final market = ref.watch(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final providerList = _providers[countryCode] ?? _providers['NG']!;
    final currencySymbol = _getCurrencySymbol(countryCode);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Internet & Wi-Fi',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/activity?query=Internet'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repeat-first: Saved Accounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Internet Accounts',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Repeat Pay',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._savedInternetAccounts.asMap().entries.map((entry) {
              final idx = entry.key;
              final acc = entry.value;
              final isSelected = _selectedSavedIndex == idx;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
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
                      child: Icon(Icons.wifi_rounded,
                          color: acc['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc['title'] as String,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${acc['providerName']} • ${acc['accountNumber']}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$currencySymbol ${Formatters.formatSatsNumber((acc['fiatAmount'] as double).round())} (${acc['planName']})',
                            style: TextStyle(
                              color: colors.primary,
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
                        backgroundColor: colors.primary,
                        foregroundColor: AppColors.charcoal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Renew / Pay',
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
            Divider(color: colors.border),
            const SizedBox(height: 16),

            // Structured Form: Add Internet Account
            Text(
              'Pay Another Internet Account',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select provider and enter account or customer reference number',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),

            // Provider Selector Chips
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
                            : colors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? p.brandColor : colors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.router_rounded,
                              size: 16,
                              color: isSelected
                                  ? p.brandColor
                                  : colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            p.name,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
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
            Text(
              'Account / Customer ID',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. 0192837465',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surfaceCard,
                prefixIcon:
                    Icon(Icons.badge_outlined, color: colors.primary, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            Text(
              'Amount ($currencySymbol)',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '$currencySymbol ',
                prefixStyle: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: colors.surfaceCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Live Sats preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated Bitcoin cost: ${Formatters.formatSats(_calculateSats(double.tryParse(_amountController.text.trim()) ?? 0, countryCode))}',
                    style: TextStyle(
                      color: colors.primary,
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
                  backgroundColor: colors.primary,
                  foregroundColor: AppColors.charcoal,
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
