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

class OperatorOption {
  final String id;
  final String name;
  final String countryCode;
  final Color brandColor;

  const OperatorOption({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.brandColor,
  });
}

enum AirtimeRecipientMode {
  myNumber,
  recent,
  someoneElse,
}

class AirtimeFlowScreen extends ConsumerStatefulWidget {
  const AirtimeFlowScreen({super.key});

  @override
  ConsumerState<AirtimeFlowScreen> createState() => _AirtimeFlowScreenState();
}

class _AirtimeFlowScreenState extends ConsumerState<AirtimeFlowScreen> {
  AirtimeRecipientMode _recipientMode = AirtimeRecipientMode.myNumber;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  String? _selectedOperatorId;
  int? _selectedPresetAmount;
  int? _selectedRecentRecipientIndex;

  final List<Map<String, String>> _recentRecipients = [
    {
      'name': 'Mom',
      'phone': '+234 803 123 4567',
      'operator': 'MTN',
      'operatorId': 'ng-mtn',
    },
    {
      'name': 'Bro David',
      'phone': '+234 802 987 6543',
      'operator': 'Airtel',
      'operatorId': 'ng-airtel',
    },
    {
      'name': 'Office Line',
      'phone': '+234 805 443 2211',
      'operator': 'Glo',
      'operatorId': 'ng-glo',
    },
    {
      'name': 'Amina (Kenya)',
      'phone': '+254 712 345 678',
      'operator': 'Safaricom',
      'operatorId': 'ke-safaricom',
    },
  ];

  final Map<String, List<OperatorOption>> _countryOperators = {
    'NG': const [
      OperatorOption(
          id: 'ng-mtn',
          name: 'MTN',
          countryCode: 'NG',
          brandColor: Color(0xFFFFCC00)),
      OperatorOption(
          id: 'ng-airtel',
          name: 'Airtel',
          countryCode: 'NG',
          brandColor: Color(0xFFFF0000)),
      OperatorOption(
          id: 'ng-glo',
          name: 'Glo',
          countryCode: 'NG',
          brandColor: Color(0xFF2E8540)),
      OperatorOption(
          id: 'ng-9mobile',
          name: '9mobile',
          countryCode: 'NG',
          brandColor: Color(0xFF005B5C)),
    ],
    'KE': const [
      OperatorOption(
          id: 'ke-safaricom',
          name: 'Safaricom',
          countryCode: 'KE',
          brandColor: Color(0xFF008542)),
      OperatorOption(
          id: 'ke-airtel',
          name: 'Airtel',
          countryCode: 'KE',
          brandColor: Color(0xFFFF0000)),
    ],
    'GH': const [
      OperatorOption(
          id: 'gh-mtn',
          name: 'MTN',
          countryCode: 'GH',
          brandColor: Color(0xFFFFCC00)),
      OperatorOption(
          id: 'gh-vodafone',
          name: 'Telecel',
          countryCode: 'GH',
          brandColor: Color(0xFFE60000)),
      OperatorOption(
          id: 'gh-airteltigo',
          name: 'AT (AirtelTigo)',
          countryCode: 'GH',
          brandColor: Color(0xFF003399)),
    ],
  };

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: '+234 803 123 4567');
    _amountController = TextEditingController(text: '1000');
    _selectedOperatorId = 'ng-mtn';
    _selectedPresetAmount = 1000;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<int> _getPresets(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'KE':
        return [100, 200, 500, 1000, 2500];
      case 'GH':
        return [10, 20, 50, 100, 200];
      case 'NG':
      default:
        return [500, 1000, 2000, 5000, 10000];
    }
  }

  String _formatCurrencyCode(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'KE':
        return 'KES';
      case 'GH':
        return 'GHS';
      case 'NG':
      default:
        return 'NGN';
    }
  }

  String _currencySymbol(String countryCode) {
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

  int _calculateSats(double fiatAmount, String countryCode) {
    double rate;
    switch (countryCode.toUpperCase()) {
      case 'KE':
        rate = 12500000.0;
        break;
      case 'GH':
        rate = 1450000.0;
        break;
      case 'NG':
      default:
        rate = 145000000.0;
    }
    final btc = fiatAmount / rate;
    return (btc * 100000000).round().clamp(10, 50000000);
  }

  void _onSelectRecipientMode(AirtimeRecipientMode mode) {
    setState(() {
      _recipientMode = mode;
      if (mode == AirtimeRecipientMode.myNumber) {
        _phoneController.text = '+234 803 123 4567';
        _selectedRecentRecipientIndex = null;
      } else if (mode == AirtimeRecipientMode.recent) {
        _selectedRecentRecipientIndex = 0;
        _phoneController.text = _recentRecipients[0]['phone']!;
        _selectedOperatorId = _recentRecipients[0]['operatorId'];
      } else {
        _phoneController.text = '';
        _selectedRecentRecipientIndex = null;
      }
    });
  }

  void _onSelectRecent(int index) {
    setState(() {
      _selectedRecentRecipientIndex = index;
      _phoneController.text = _recentRecipients[index]['phone']!;
      _selectedOperatorId = _recentRecipients[index]['operatorId'];
    });
  }

  void _handlePresetSelect(int amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _handleContinueToPay(String countryCode) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter an amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final operators =
        _countryOperators[countryCode] ?? _countryOperators['NG']!;
    final operator = operators.firstWhere(
      (op) => op.id == _selectedOperatorId,
      orElse: () => operators.first,
    );

    final sats = _calculateSats(amount, countryCode);
    final fiatCode = _formatCurrencyCode(countryCode);

    await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Airtime Purchase',
      billerName: operator.name,
      accountReference: phone,
      fiatAmount: amount,
      fiatCurrency: fiatCode,
      amountSats: sats,
      serviceIcon: Icons.phone_android_rounded,
      onConfirm: () async {
        await Future.delayed(const Duration(milliseconds: 500));

        final tx = TransactionModel(
          id: 'air_${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.airtime,
          status: TransactionStatus.completed,
          amountSats: sats,
          fiatAmount: amount,
          fiatCurrency: fiatCode,
          recipientOrSender: operator.name,
          billerName: operator.name,
          accountReference: phone,
          receiptReference:
              'AIR-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          spendCountry: countryCode,
          description: '${operator.name} Airtime Recharge ($phone)',
          createdAt: DateTime.now(),
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);

        if (mounted) {
          PaymentSuccessSheet.show(
            context,
            transaction: tx,
            billerName: operator.name,
            accountReference: phone,
            fiatAmount: amount,
            fiatCurrency: fiatCode,
            amountSats: sats,
            serviceTitle: 'Airtime sent',
            onDone: () => Navigator.of(context).pop(),
            onBuyAgain: () {
              // Stay on airtime screen to buy again
            },
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
    final operators =
        _countryOperators[countryCode] ?? _countryOperators['NG']!;
    final presets = _getPresets(countryCode);
    final currencySymbol = _currencySymbol(countryCode);
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final currentSats = _calculateSats(currentAmount, countryCode);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Buy Airtime',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/activity?query=Airtime'),
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
            // 1. Recipient Selector Segmented Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _buildSegment(
                    'My Number',
                    AirtimeRecipientMode.myNumber,
                    Icons.person_rounded,
                  ),
                  _buildSegment(
                    'Recent',
                    AirtimeRecipientMode.recent,
                    Icons.history_rounded,
                  ),
                  _buildSegment(
                    'Someone Else',
                    AirtimeRecipientMode.someoneElse,
                    Icons.contacts_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent Recipients Chips (When in Recent mode)
            if (_recipientMode == AirtimeRecipientMode.recent) ...[
              Text(
                'Recent Recipients',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _recentRecipients.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final rec = entry.value;
                    final isSelected = _selectedRecentRecipientIndex == idx;

                    return GestureDetector(
                      onTap: () => _onSelectRecent(idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  colors.primary.withValues(alpha: 0.2),
                              child: Text(
                                rec['name']![0],
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec['name']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${rec['operator']} • ${rec['phone']}',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Phone Number Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phone Number',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_recipientMode == AirtimeRecipientMode.someoneElse)
                  GestureDetector(
                    onTap: () {
                      _phoneController.text = '+234 809 999 0000';
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Icon(Icons.contacts, size: 14, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Contacts',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: '+234 800 000 0000',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surfaceCard,
                prefixIcon: Icon(Icons.phone_iphone_rounded,
                    color: colors.primary, size: 20),
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
            const SizedBox(height: 20),

            // 2. Operator Network Selector
            Text(
              'Select Operator Network',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: operators.map((op) {
                final isSelected = op.id == _selectedOperatorId;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOperatorId = op.id),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? op.brandColor.withValues(alpha: 0.18)
                            : colors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? op.brandColor : colors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: op.brandColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            op.name,
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
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 3. Amount Presets
            Text(
              'Select Amount',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final isSelected = _selectedPresetAmount == p;
                return GestureDetector(
                  onTap: () => _handlePresetSelect(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                    child: Text(
                      '$currencySymbol ${Formatters.formatSatsNumber(p)}',
                      style: TextStyle(
                        color: isSelected ? colors.primary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Amount Input
            Text(
              'Custom Amount ($currencySymbol)',
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
              onChanged: (val) {
                setState(() {
                  _selectedPresetAmount = int.tryParse(val);
                });
              },
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
            const SizedBox(height: 12),

            // Live Sats preview badge
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
                    'Estimated Bitcoin cost: ${Formatters.formatSats(currentSats)}',
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

            // 4. Continue Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleContinueToPay(countryCode),
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

  Widget _buildSegment(String label, AirtimeRecipientMode mode, IconData icon) {
    final colors = context.colors;
    final isSelected = _recipientMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSelectRecipientMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.charcoal : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.charcoal : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
