import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

enum InsightsPeriod {
  thisWeek('This week'),
  thisMonth('This month'),
  lastMonth('Last month'),
  threeMonths('3 months'),
  thisYear('This year'),
  custom('Custom');

  final String label;
  const InsightsPeriod(this.label);
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsPeriod _selectedPeriod = InsightsPeriod.thisMonth;
  final _numberFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final privacy = ref.watch(privacyProvider);
    final demoState = ref.watch(demoModeProvider);

    // Filter aggregated statistics based on demo dataset
    final int moneyInSats = 950000;
    final int moneyOutSats = 403300;
    final int netFlowSats = moneyInSats - moneyOutSats;
    final int totalFeesSats = 1250;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Financial Insights',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Demo Banner
          if (demoState.isEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Period Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InsightsPeriod.values.map((period) {
                final isSelected = period == _selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      period.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.darkCardBackground,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedPeriod = period);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Overview Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Money In',
                  satsAmount: moneyInSats,
                  currency: currency,
                  isHidden: privacy.isBalanceHidden,
                  color: const Color(0xFF10B981),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Money Out',
                  satsAmount: moneyOutSats,
                  currency: currency,
                  isHidden: privacy.isBalanceHidden,
                  color: const Color(0xFFEF4444),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Net Flow',
                  satsAmount: netFlowSats,
                  currency: currency,
                  isHidden: privacy.isBalanceHidden,
                  color: netFlowSats >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  icon: Icons.swap_vert_rounded,
                  isNetFlow: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Network & App Fees',
                  satsAmount: totalFeesSats,
                  currency: currency,
                  isHidden: privacy.isBalanceHidden,
                  color: AppColors.primary,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Multi-Asset Allocation (Requirement 24)
          const Text(
            'Asset Allocation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Portfolio distribution across Bitcoin and digital dollar stablecoins.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildAssetAllocationCard(
              demoState.isEnabled, privacy.isBalanceHidden),
          const SizedBox(height: 16),

          // Conversion Activity
          _buildConversionActivityCard(
              demoState.isEnabled, privacy.isBalanceHidden),

          const SizedBox(height: 24),

          // Spending by Category
          const Text(
            'Spending by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildCategoryItem(
            name: 'Bitcoin Transfers',
            satsAmount: 250000,
            percent: '62%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.currency_bitcoin,
            color: const Color(0xFFF7931A),
          ),
          _buildCategoryItem(
            name: 'Protected Payments',
            satsAmount: 300000,
            percent: '74%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.shield_outlined,
            color: const Color(0xFF38BDF8),
          ),
          _buildCategoryItem(
            name: 'Utilities & Bills (Electricity/TV/Net)',
            satsAmount: 36300,
            percent: '9%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.flash_on_outlined,
            color: const Color(0xFFEAB308),
          ),
          _buildCategoryItem(
            name: 'Airtime & Mobile Data',
            satsAmount: 8500,
            percent: '2%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.phone_android_outlined,
            color: const Color(0xFF10B981),
          ),
          _buildCategoryItem(
            name: 'Travel & eSIMs',
            satsAmount: 12000,
            percent: '3%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.flight_takeoff_outlined,
            color: const Color(0xFF8B5CF6),
          ),
          _buildCategoryItem(
            name: 'Cards & Online Funding',
            satsAmount: 45000,
            percent: '11%',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.credit_card_outlined,
            color: const Color(0xFFEC4899),
          ),

          const SizedBox(height: 24),

          // Spending by Country / Market
          const Text(
            'Spending by Country / Spend Market',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aggregated spend based on merchant and biller countries visited or paid.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          _buildCountrySpendCard(
            countryName: 'Kenya',
            flagEmoji: '🇰🇪',
            currencyLabel: 'KES',
            localAmount: 'KSh 1,934',
            satsAmount: 24800,
            currency: currency,
            isHidden: privacy.isBalanceHidden,
          ),
          _buildCountrySpendCard(
            countryName: 'Nigeria',
            flagEmoji: '🇳🇬',
            currencyLabel: 'NGN',
            localAmount: '₦ 22,325',
            satsAmount: 23500,
            currency: currency,
            isHidden: privacy.isBalanceHidden,
          ),
          _buildCountrySpendCard(
            countryName: 'Ghana',
            flagEmoji: '🇬🇭',
            currencyLabel: 'GHS',
            localAmount: 'GH₵ 110',
            satsAmount: 12200,
            currency: currency,
            isHidden: privacy.isBalanceHidden,
          ),

          const SizedBox(height: 24),

          // Spending by Currency
          const Text(
            'Currencies Used in Spend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Converted on-demand from Bitcoin satoshis. Hanbova holds 100% sats.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          _buildCurrencyUsageRow(
              'KES (Kenya Shilling)', 'KSh 1,934', '24,800 sats'),
          _buildCurrencyUsageRow(
              'NGN (Nigeria Naira)', '₦ 22,325', '23,500 sats'),
          _buildCurrencyUsageRow(
              'USD (US Dollar / eSIM & Cards)', '\$ 38.00', '57,000 sats'),
          _buildCurrencyUsageRow('GHS (Ghana Cedi)', 'GH₵ 110', '12,200 sats'),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int satsAmount,
    required FiatCurrency currency,
    required bool isHidden,
    required Color color,
    required IconData icon,
    bool isNetFlow = false,
  }) {
    final prefix = isNetFlow && satsAmount > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHidden
                ? '•••• sats'
                : '$prefix${_numberFormat.format(satsAmount)} sats',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isHidden ? '≈ ••••' : '≈ ${currency.format(satsAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String name,
    required int satsAmount,
    required String percent,
    required FiatCurrency currency,
    required bool isHidden,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  percent,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isHidden
                    ? '•••• sats'
                    : '${_numberFormat.format(satsAmount)} sats',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isHidden ? '≈ ••••' : '≈ ${currency.format(satsAmount)}',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySpendCard({
    required String countryName,
    required String flagEmoji,
    required String currencyLabel,
    required String localAmount,
    required int satsAmount,
    required FiatCurrency currency,
    required bool isHidden,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Text(flagEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Local: $localAmount',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isHidden
                    ? '•••• sats'
                    : '${_numberFormat.format(satsAmount)} sats',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isHidden
                    ? 'Home: ••••'
                    : 'Home: ${currency.format(satsAmount)}',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyUsageRow(
      String title, String localSpend, String satsUsed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Text(
                localSpend,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($satsUsed)',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetAllocationCard(bool isDemo, bool isHidden) {
    // In demo mode: BTC 37%, USDT 39%, USDC 24%
    // In normal mode: BTC 100%, USDT 0%, USDC 0%
    final btcPct = isDemo ? 37 : 100;
    final usdtPct = isDemo ? 39 : 0;
    final usdcPct = isDemo ? 24 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Holdings',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isDemo
                      ? (isHidden ? '••••••' : '≈ \$3,170.00 USD')
                      : (isHidden ? '••••••' : '100% Bitcoin'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: btcPct,
                    child: Container(color: const Color(0xFFF7931A)),
                  ),
                  if (usdtPct > 0)
                    Expanded(
                      flex: usdtPct,
                      child: Container(color: const Color(0xFF26A17B)),
                    ),
                  if (usdcPct > 0)
                    Expanded(
                      flex: usdcPct,
                      child: Container(color: const Color(0xFF2775CA)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Asset Breakdown Chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildAllocationLegendItem(
                color: const Color(0xFFF7931A),
                label: 'Bitcoin (BTC)',
                pct: '$btcPct%',
                value: isHidden ? '••••' : (isDemo ? '1.8M sats' : 'Active'),
              ),
              _buildAllocationLegendItem(
                color: const Color(0xFF26A17B),
                label: 'Tether (USDT)',
                pct: '$usdtPct%',
                value: isHidden ? '••••' : (isDemo ? '\$1,250' : '\$0'),
              ),
              _buildAllocationLegendItem(
                color: const Color(0xFF2775CA),
                label: 'USD Coin (USDC)',
                pct: '$usdcPct%',
                value: isHidden ? '••••' : (isDemo ? '\$750' : '\$0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationLegendItem({
    required Color color,
    required String label,
    required String pct,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label $pct',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConversionActivityCard(bool isDemo, bool isHidden) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Conversion Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDemo ? '2 Swaps' : '0 Swaps',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isDemo
                ? (isHidden
                    ? '••••••'
                    : 'Converted volume: \$1,450.00 • Active pairs: BTC/USDT, USDT/USDC • Spread savings: ≈ 2.4% vs local OTC')
                : 'No conversion history yet. Use Convert on Home to swap between BTC, USDT, and USDC.',
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
