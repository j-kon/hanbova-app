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

class SavedMeter {
  final String id;
  final String discoName;
  final String meterNumber;
  final String customerName;
  final String countryCode;

  const SavedMeter({
    required this.id,
    required this.discoName,
    required this.meterNumber,
    required this.customerName,
    required this.countryCode,
  });
}

class ElectricityFlowScreen extends ConsumerStatefulWidget {
  const ElectricityFlowScreen({super.key});

  @override
  ConsumerState<ElectricityFlowScreen> createState() =>
      _ElectricityFlowScreenState();
}

class _ElectricityFlowScreenState extends ConsumerState<ElectricityFlowScreen> {
  bool _useSavedMeter = true;
  String? _selectedSavedMeterId;
  String _selectedDisco = 'Ikeja Electric (IKEDC)';
  late TextEditingController _meterController;
  late TextEditingController _amountController;
  int? _selectedPreset;

  final List<SavedMeter> _savedMeters = const [
    SavedMeter(
      id: 'meter-1',
      discoName: 'Ikeja Electric (IKEDC)',
      meterNumber: '04182938192',
      customerName: 'Adekunle J. (Home)',
      countryCode: 'NG',
    ),
    SavedMeter(
      id: 'meter-2',
      discoName: 'Eko Electric (EKEDC)',
      meterNumber: '54129847102',
      customerName: 'Studio / Office',
      countryCode: 'NG',
    ),
    SavedMeter(
      id: 'meter-3',
      discoName: 'Kenya Power (KPLC Prepaid)',
      meterNumber: '37189201948',
      customerName: 'Nairobi Apartment',
      countryCode: 'KE',
    ),
  ];

  final List<String> _ngDiscos = const [
    'Ikeja Electric (IKEDC)',
    'Eko Electric (EKEDC)',
    'Abuja Electricity (AEDC)',
    'Ibadan Electricity (IBEDC)',
    'Enugu Electricity (EEDC)',
    'Kano Electricity (KEDCO)',
  ];

  final List<String> _keDiscos = const [
    'Kenya Power (KPLC Prepaid)',
    'Kenya Power (KPLC Postpaid)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSavedMeterId = 'meter-1';
    _meterController = TextEditingController(text: '04182938192');
    _amountController = TextEditingController(text: '5000');
    _selectedPreset = 5000;
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSelectSavedMeter(SavedMeter meter) {
    setState(() {
      _selectedSavedMeterId = meter.id;
      _selectedDisco = meter.discoName;
      _meterController.text = meter.meterNumber;
      _useSavedMeter = true;
    });
  }

  Future<void> _proceedToConfirmation() async {
    final market = ref.read(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final currency = ref.read(currencyProvider);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final amountSats = currency.fiatToSats(amount);
    final disco = _useSavedMeter && _selectedSavedMeterId != null
        ? _savedMeters
            .firstWhere((m) => m.id == _selectedSavedMeterId)
            .discoName
        : _selectedDisco;
    final meterNo = _meterController.text.trim();

    // Deterministic 20-digit token generator
    final token =
        '4829-${(DateTime.now().millisecondsSinceEpoch % 9000 + 1000)}-${(DateTime.now().millisecondsSinceEpoch % 8000 + 1000)}-${(DateTime.now().millisecondsSinceEpoch % 7000 + 1000)}-4821';

    final confirmed = await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Electricity Payment',
      billerName: disco,
      accountReference: meterNo,
      accountHolderName:
          _useSavedMeter ? 'Adekunle J. (Verified)' : 'Verified Customer',
      fiatAmount: amount,
      fiatCurrency: countryCode == 'KE' ? 'KES' : 'NGN',
      amountSats: amountSats,
      feeSats: 50,
      serviceIcon: Icons.electric_bolt_rounded,
      onConfirm: () async {
        final tx = TransactionModel(
          id: 'tx-elec-${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.electricity,
          status: TransactionStatus.completed,
          amountSats: amountSats,
          recipientOrSender: disco,
          description: '$disco Recharge',
          createdAt: DateTime.now(),
          fiatAmount: amount,
          fiatCurrency: countryCode == 'KE' ? 'KES' : 'NGN',
          feeSats: 50,
          billerName: disco,
          accountReference: meterNo,
          tokenOrPin: token,
          paymentMethod: 'Bitcoin Wallet',
          spendCountry: countryCode,
          receiptReference: 'ELEC-${DateTime.now().millisecondsSinceEpoch}',
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);
      },
    );

    if (confirmed == true && mounted) {
      final tx = TransactionModel(
        id: 'tx-elec-recent',
        type: TransactionType.electricity,
        status: TransactionStatus.completed,
        amountSats: amountSats,
        recipientOrSender: disco,
        description: '$disco Recharge',
        createdAt: DateTime.now(),
        fiatAmount: amount,
        fiatCurrency: countryCode == 'KE' ? 'KES' : 'NGN',
        feeSats: 50,
        billerName: disco,
        accountReference: meterNo,
        tokenOrPin: token,
        paymentMethod: 'Bitcoin Wallet',
        spendCountry: countryCode,
        receiptReference: 'ELEC-REC-${DateTime.now().millisecondsSinceEpoch}',
      );

      await PaymentSuccessSheet.show(
        context,
        transaction: tx,
        billerName: disco,
        accountReference: meterNo,
        fiatAmount: amount,
        fiatCurrency: countryCode == 'KE' ? 'KES' : 'NGN',
        amountSats: amountSats,
        electricityTokenOrPin: token,
        onDone: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final currency = ref.watch(currencyProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final isKenya = countryCode == 'KE';
    final discos = isKenya ? _keDiscos : _ngDiscos;
    final relevantSaved = _savedMeters
        .where((m) => m.countryCode == (isKenya ? 'KE' : 'NG'))
        .toList();

    final presets =
        isKenya ? [500, 1000, 2000, 5000] : [2000, 5000, 10000, 20000];
    final sym = isKenya ? 'KSh' : '₦';
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final estimatedSats = currency.fiatToSats(amount);

    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Pay Electricity',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/activity?query=Electricity'),
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
            // Saved Meter vs New Meter Toggle
            if (relevantSaved.isNotEmpty) ...[
              Text(
                'Select Saved Meter',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...relevantSaved.map((sm) {
                final isSelected =
                    _useSavedMeter && _selectedSavedMeterId == sm.id;
                return GestureDetector(
                  onTap: () => _onSelectSavedMeter(sm),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
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
                            color: colors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.electric_meter_rounded,
                              color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sm.customerName,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sm.discoName} • ${sm.meterNumber}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: colors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _useSavedMeter = false;
                    _selectedSavedMeterId = null;
                    _meterController.text = '';
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Use a Different Meter Number'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // If new meter or editing
            if (!_useSavedMeter || relevantSaved.isEmpty) ...[
              Text(
                'Select Distribution Company (DISCO)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: discos.contains(_selectedDisco)
                        ? _selectedDisco
                        : discos.first,
                    isExpanded: true,
                    dropdownColor: colors.surfaceCard,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: discos.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDisco = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Meter / Account Number',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceCard,
                  prefixIcon: Icon(Icons.numbers,
                      color: colors.textSecondary, size: 20),
                  hintText: 'Enter 11-digit meter number',
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
              const SizedBox(height: 20),
            ],

            // Amount Presets
            Text(
              'Select Amount',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                final isSelected = _selectedPreset == preset;
                return ChoiceChip(
                  label: Text('$sym ${NumberFormat('#,##0').format(preset)}'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedPreset = preset;
                      _amountController.text = preset.toString();
                    });
                  },
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceCard,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.charcoal : colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? colors.primary : colors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Custom Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _selectedPreset = int.tryParse(val);
                });
              },
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceCard,
                prefixText: '$sym ',
                prefixStyle: TextStyle(
                  color: colors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'Recharge amount',
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
            const SizedBox(height: 10),

            // Satoshi Conversion
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Bitcoin Cost: ≈ ${Formatters.formatSats(estimatedSats)}',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Token Delivery Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.token_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your 20-digit prepaid recharge token is generated instantly upon payment, displayed on your receipt, and saved to Activity.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: amount > 0 ? _proceedToConfirmation : null,
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
