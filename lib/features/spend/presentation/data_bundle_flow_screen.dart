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

class DataPackage {
  final String id;
  final String operatorName;
  final String allowance;
  final String validity;
  final double fiatPrice;
  final String category; // 'Daily', 'Weekly', 'Monthly'

  const DataPackage({
    required this.id,
    required this.operatorName,
    required this.allowance,
    required this.validity,
    required this.fiatPrice,
    required this.category,
  });
}

class DataBundleFlowScreen extends ConsumerStatefulWidget {
  const DataBundleFlowScreen({super.key});

  @override
  ConsumerState<DataBundleFlowScreen> createState() =>
      _DataBundleFlowScreenState();
}

class _DataBundleFlowScreenState extends ConsumerState<DataBundleFlowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _phoneController;
  String _selectedOperator = 'MTN';

  final List<DataPackage> _allPackages = const [
    // Daily
    DataPackage(
        id: 'pkg-1',
        operatorName: 'MTN',
        allowance: '1GB',
        validity: '1 Day',
        fiatPrice: 350.0,
        category: 'Daily'),
    DataPackage(
        id: 'pkg-2',
        operatorName: 'MTN',
        allowance: '2.5GB',
        validity: '2 Days',
        fiatPrice: 600.0,
        category: 'Daily'),
    DataPackage(
        id: 'pkg-3',
        operatorName: 'Airtel',
        allowance: '1GB',
        validity: '1 Day',
        fiatPrice: 350.0,
        category: 'Daily'),

    // Weekly
    DataPackage(
        id: 'pkg-4',
        operatorName: 'MTN',
        allowance: '3.5GB',
        validity: '7 Days',
        fiatPrice: 1500.0,
        category: 'Weekly'),
    DataPackage(
        id: 'pkg-5',
        operatorName: 'MTN',
        allowance: '6GB',
        validity: '7 Days',
        fiatPrice: 2500.0,
        category: 'Weekly'),
    DataPackage(
        id: 'pkg-6',
        operatorName: 'Airtel',
        allowance: '4GB',
        validity: '7 Days',
        fiatPrice: 1600.0,
        category: 'Weekly'),

    // Monthly
    DataPackage(
        id: 'pkg-7',
        operatorName: 'MTN',
        allowance: '12GB',
        validity: '30 Days',
        fiatPrice: 4500.0,
        category: 'Monthly'),
    DataPackage(
        id: 'pkg-8',
        operatorName: 'MTN',
        allowance: '25GB',
        validity: '30 Days',
        fiatPrice: 8000.0,
        category: 'Monthly'),
    DataPackage(
        id: 'pkg-9',
        operatorName: 'MTN',
        allowance: '50GB',
        validity: '30 Days',
        fiatPrice: 15000.0,
        category: 'Monthly'),
    DataPackage(
        id: 'pkg-10',
        operatorName: 'Airtel',
        allowance: '15GB',
        validity: '30 Days',
        fiatPrice: 5000.0,
        category: 'Monthly'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _phoneController = TextEditingController(text: '+234 803 123 4567');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _purchasePackage(DataPackage pkg) async {
    final market = ref.read(marketProvider);
    final countryCode = market.spendCountry.toUpperCase();
    final currency = ref.read(currencyProvider);
    final amountSats = currency.fiatToSats(pkg.fiatPrice);

    final confirmed = await PaymentConfirmationSheet.show(
      context,
      title: 'Confirm Data Bundle',
      billerName: '${pkg.operatorName} Data Bundle',
      accountReference: _phoneController.text.trim(),
      planOrBouquetName: '${pkg.allowance} (${pkg.validity})',
      fiatAmount: pkg.fiatPrice,
      fiatCurrency: 'NGN',
      amountSats: amountSats,
      feeSats: 50,
      serviceIcon: Icons.wifi_rounded,
      onConfirm: () async {
        final tx = TransactionModel(
          id: 'tx-data-${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.data,
          status: TransactionStatus.completed,
          amountSats: amountSats,
          recipientOrSender: _phoneController.text.trim(),
          description:
              '${pkg.operatorName} ${pkg.allowance} Data (${pkg.validity})',
          createdAt: DateTime.now(),
          fiatAmount: pkg.fiatPrice,
          fiatCurrency: 'NGN',
          feeSats: 50,
          billerName: '${pkg.operatorName} Data',
          accountReference: _phoneController.text.trim(),
          planName: '${pkg.allowance} / ${pkg.validity}',
          paymentMethod: 'Bitcoin Wallet',
          spendCountry: countryCode,
          receiptReference: 'DAT-${DateTime.now().millisecondsSinceEpoch}',
        );

        ref.read(transactionsProvider.notifier).addTransaction(tx);
      },
    );

    if (confirmed == true && mounted) {
      final tx = TransactionModel(
        id: 'tx-data-recent',
        type: TransactionType.data,
        status: TransactionStatus.completed,
        amountSats: amountSats,
        recipientOrSender: _phoneController.text.trim(),
        description:
            '${pkg.operatorName} ${pkg.allowance} Data (${pkg.validity})',
        createdAt: DateTime.now(),
        fiatAmount: pkg.fiatPrice,
        fiatCurrency: 'NGN',
        feeSats: 50,
        billerName: '${pkg.operatorName} Data',
        accountReference: _phoneController.text.trim(),
        planName: '${pkg.allowance} / ${pkg.validity}',
        paymentMethod: 'Bitcoin Wallet',
        spendCountry: countryCode,
        receiptReference: 'DAT-REC-${DateTime.now().millisecondsSinceEpoch}',
      );

      await PaymentSuccessSheet.show(
        context,
        transaction: tx,
        billerName: '${pkg.operatorName} Data',
        accountReference: _phoneController.text.trim(),
        fiatAmount: pkg.fiatPrice,
        fiatCurrency: 'NGN',
        amountSats: amountSats,
        onDone: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Buy Data Bundles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone Number input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.darkCardBackground,
                    prefixIcon: const Icon(Icons.phone_android,
                        color: AppColors.darkTextSecondary, size: 20),
                    hintText: 'Recipient phone number',
                    hintStyle:
                        const TextStyle(color: AppColors.darkTextSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Operator toggle buttons
                Row(
                  children: ['MTN', 'Airtel', 'Glo', '9mobile'].map((op) {
                    final isSelected = _selectedOperator == op;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedOperator = op),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.darkCardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            op,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.darkTextSecondary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),

          // Packages List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPackageList('Daily', currency),
                _buildPackageList('Weekly', currency),
                _buildPackageList('Monthly', currency),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList(String category, dynamic currency) {
    final packages = _allPackages
        .where((p) =>
            p.category == category &&
            p.operatorName.toUpperCase() == _selectedOperator.toUpperCase())
        .toList();

    if (packages.isEmpty) {
      return const Center(
        child: Text(
          'No packages available in this category',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final sats = currency.fiatToSats(pkg.fiatPrice);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.wifi, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.allowance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valid for ${pkg.validity}',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
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
                    '₦${NumberFormat('#,##0').format(pkg.fiatPrice)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${Formatters.formatSats(sats)} sats',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _purchasePackage(pkg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
