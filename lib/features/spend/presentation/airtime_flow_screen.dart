import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/currency/currency_provider.dart';
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

class AirtimeFlowScreen extends ConsumerStatefulWidget {
  const AirtimeFlowScreen({super.key});

  @override
  ConsumerState<AirtimeFlowScreen> createState() => _AirtimeFlowScreenState();
}

class _AirtimeFlowScreenState extends ConsumerState<AirtimeFlowScreen> {
  bool _isMyNumber = true;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  String? _selectedOperatorId;
  int? _selectedPresetAmount;

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
    _phoneController.disposeDisposeSafely();
    _amountController.disposeDisposeSafely();
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

  void _onToggleMyNumber(bool isMy) {
    setState(() {
      _isMyNumber = isMy;
      if (isMy) {
        final market = ref.read(marketProvider);
        if (market.spendCountry.toUpperCase() == 'KE') {
          _phoneController.text = '+254 712 345 678';
        } else {
          _phoneController.text = '+234 803 123 4567';
        }
      } else {
        _phoneController.text = '';
      }
    });
  }

  void _onSelectPreset(int amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _onCustomAmountChanged(String val) {
    final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
    setState(() {
      _selectedPresetAmount = parsed;
    });
  }

  Future<void> _proceedToConfirmation() async {
    final market = ref.read(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final currencyCode = _formatCurrencyCode(countryCode);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final operators =
        _countryOperators[countryCode] ?? _countryOperators['NG']!;
    final op = operators.firstWhere(
      (o) => o.id == _selectedOperatorId,
      orElse: () => operators.first,
    );

    // Dynamic sats conversion
    final currency = ref.read(currencyProvider);
    final amountSats = currency.fiatToSats(amount);

    final confirmed = await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Airtime Recharge',
      billerName: '${op.name} Airtime',
      accountReference: _phoneController.text.trim(),
      fiatAmount: amount,
      fiatCurrency: currencyCode,
      amountSats: amountSats,
      feeSats: 50,
      serviceIcon: Icons.phone_android_rounded,
      onConfirm: () async {
        // Record in transactions list
        final tx = TransactionModel(
          id: 'tx-airtime-${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.airtime,
          status: TransactionStatus.completed,
          amountSats: amountSats,
          recipientOrSender: _phoneController.text.trim(),
          description: '${op.name} Airtime Recharge',
          createdAt: DateTime.now(),
          fiatAmount: amount,
          fiatCurrency: currencyCode,
          feeSats: 50,
          billerName: '${op.name} Airtime',
          accountReference: _phoneController.text.trim(),
          paymentMethod: 'Bitcoin Wallet',
          spendCountry: countryCode,
          receiptReference: 'AIR-${DateTime.now().millisecondsSinceEpoch}',
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);
      },
    );

    if (confirmed == true && mounted) {
      final tx = TransactionModel(
        id: 'tx-airtime-recent',
        type: TransactionType.airtime,
        status: TransactionStatus.completed,
        amountSats: amountSats,
        recipientOrSender: _phoneController.text.trim(),
        description: '${op.name} Airtime Recharge',
        createdAt: DateTime.now(),
        fiatAmount: amount,
        fiatCurrency: currencyCode,
        feeSats: 50,
        billerName: '${op.name} Airtime',
        accountReference: _phoneController.text.trim(),
        paymentMethod: 'Bitcoin Wallet',
        spendCountry: countryCode,
        receiptReference: 'AIR-REC-${DateTime.now().millisecondsSinceEpoch}',
      );

      await PaymentSuccessSheet.show(
        context,
        transaction: tx,
        billerName: '${op.name} Airtime',
        accountReference: _phoneController.text.trim(),
        fiatAmount: amount,
        fiatCurrency: currencyCode,
        amountSats: amountSats,
        onDone: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final currency = ref.watch(currencyProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final operators =
        _countryOperators[countryCode] ?? _countryOperators['NG']!;
    final presets = _getPresets(countryCode);
    final sym = _currencySymbol(countryCode);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final estimatedSats = currency.fiatToSats(amount);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Buy Airtime',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(market.spendCountryInfo.flagEmoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  market.spendCountryInfo.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Number Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.darkCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _onToggleMyNumber(true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isMyNumber
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Number',
                          style: TextStyle(
                            color: _isMyNumber ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _onToggleMyNumber(false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isMyNumber
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Someone Else',
                          style: TextStyle(
                            color: !_isMyNumber ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operator Selector
            const Text(
              'Select Mobile Operator',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: operators.map((op) {
                final isSelected = _selectedOperatorId == op.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOperatorId = op.id),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? op.brandColor.withValues(alpha: 0.2)
                            : AppColors.darkCardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? op.brandColor : AppColors.darkBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        op.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.darkTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Phone Number Input
            const Text(
              'Phone Number',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkCardBackground,
                prefixIcon: const Icon(Icons.phone_android,
                    color: AppColors.darkTextSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts_rounded,
                      color: AppColors.primary, size: 20),
                  onPressed: () {
                    // Pre-fill a sample contact
                    setState(() {
                      _phoneController.text = '+234 802 987 6543';
                      _isMyNumber = false;
                    });
                  },
                ),
                hintText: 'Enter phone number',
                hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
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
            const SizedBox(height: 24),

            // Amount Presets
            const Text(
              'Select Amount',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                final isSelected = _selectedPresetAmount == preset;
                return ChoiceChip(
                  label: Text('$sym ${NumberFormat('#,##0').format(preset)}'),
                  selected: isSelected,
                  onSelected: (_) => _onSelectPreset(preset),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.darkCardBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.primary : AppColors.darkBorder,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _onCustomAmountChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkCardBackground,
                prefixText: '$sym ',
                prefixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'Custom amount',
                hintStyle: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 16,
                ),
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

            // Live Satoshi Deduction Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated Satoshi Cost: ≈ ${Formatters.formatSats(estimatedSats)} sats',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: amount > 0 ? _proceedToConfirmation : null,
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

extension SafeDispose on TextEditingController {
  void disposeDisposeSafely() {
    dispose();
  }
}
