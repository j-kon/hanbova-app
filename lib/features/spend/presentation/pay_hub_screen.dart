import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/market/country_model.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../beneficiaries/presentation/beneficiaries_screen.dart';
import '../../cards/presentation/cards_screen.dart';
import '../../request_money/presentation/request_money_screen.dart';
import 'airtime_flow_screen.dart';
import 'data_bundle_flow_screen.dart';
import 'electricity_flow_screen.dart';
import 'saved_payments_screen.dart';
import 'tv_subscription_flow_screen.dart';

class PayHubScreen extends ConsumerWidget {
  const PayHubScreen({super.key});

  void _showSpendMarketSelector(BuildContext context, WidgetRef ref) {
    final market = ref.read(marketProvider);
    const countries = CountryInfo.supportedCountries;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.darkBorder),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Spend Market',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.flight_takeoff_rounded,
                      color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Switch your spending market to pay local bills while traveling. Your legal residence remains unchanged.',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ...countries.map((c) {
                final isSelected =
                    c.code.toUpperCase() == market.spendCountry.toUpperCase();
                return ListTile(
                  leading:
                      Text(c.flagEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Currency: ${c.defaultCurrency.code}',
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  onTap: () {
                    ref.read(marketProvider.notifier).setSpendCountry(c.code);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Pay & Spend Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Spend Market Switcher Pill
          GestureDetector(
            onTap: () => _showSpendMarketSelector(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(spendCountry.flagEmoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    spendCountry.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pay Again Section
            _buildSectionHeader('Pay Again', 'Quick repeat for frequent bills'),
            const SizedBox(height: 12),
            _buildPayAgainCarousel(context),
            const SizedBox(height: 28),

            // Everyday Services Grid
            _buildSectionHeader(
                'Everyday Bills & Utilities', 'Instant Bitcoin settlement'),
            const SizedBox(height: 14),
            _buildServicesGrid(context, spendCountry.code),
            const SizedBox(height: 28),

            // Financial Actions & Management
            _buildSectionHeader(
                'Payment Management', 'Cards, beneficiaries, and requests'),
            const SizedBox(height: 12),
            _buildManagementCards(context),
            const SizedBox(height: 32),

            // Safety Reassurance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Bitcoin Backed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hanbova holds zero local fiat balances. Local airtime, electricity, and bills are paid on-demand directly from your satoshis.',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPayAgainCarousel(BuildContext context) {
    final recentItems = [
      {
        'title': 'Mom\'s MTN',
        'subtitle': '+234 803 123 4567',
        'amount': '₦ 2,000',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFFFFCC00),
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AirtimeFlowScreen()),
            ),
      },
      {
        'title': 'Home IKEDC',
        'subtitle': 'Meter: 04182938192',
        'amount': '₦ 10,000',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFFFBBF24),
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ElectricityFlowScreen()),
            ),
      },
      {
        'title': 'DStv Compact',
        'subtitle': 'Smartcard: 1029384756',
        'amount': '₦ 15,700',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFA78BFA),
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const TvSubscriptionFlowScreen()),
            ),
      },
      {
        'title': 'Nairobi KPLC',
        'subtitle': 'Meter: 37189201948',
        'amount': 'KSh 1,000',
        'icon': Icons.electric_meter_rounded,
        'color': const Color(0xFF34D399),
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ElectricityFlowScreen()),
            ),
      },
    ];

    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recentItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = recentItems[index];
          return GestureDetector(
            onTap: item['action'] as VoidCallback,
            child: Container(
              width: 175,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (item['color'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: item['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['amount'] as String,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context, String countryCode) {
    final services = [
      {
        'title': 'Airtime',
        'desc': 'Instant top-up',
        'icon': Icons.phone_android_rounded,
        'color': AppColors.primary,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AirtimeFlowScreen()),
            ),
      },
      {
        'title': 'Data Bundles',
        'desc': 'Daily, weekly, monthly',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF38BDF8),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const DataBundleFlowScreen()),
            ),
      },
      {
        'title': 'Electricity',
        'desc': 'Prepaid token generator',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFFFBBF24),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ElectricityFlowScreen()),
            ),
      },
      {
        'title': 'TV Cables',
        'desc': 'DStv, GOtv, StarTimes',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFA78BFA),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const TvSubscriptionFlowScreen()),
            ),
      },
      {
        'title': 'Internet',
        'desc': 'Fibre & 5G routers',
        'icon': Icons.router_rounded,
        'color': const Color(0xFF34D399),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const DataBundleFlowScreen()),
            ),
      },
      {
        'title': 'Water Bills',
        'desc': 'Utility supply',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF60A5FA),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ElectricityFlowScreen()),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return GestureDetector(
          onTap: item['onTap'] as VoidCallback,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 22,
                    color: item['color'] as Color,
                  ),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementCards(BuildContext context) {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.bookmark_added_rounded,
          iconColor: AppColors.primary,
          title: 'Saved Payments & Billers',
          subtitle: 'Manage saved meters, TV accounts, and recurring bills',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const SavedPaymentsScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: 'Beneficiaries & Contacts',
          subtitle: 'Saved peer recipients, lightning addresses, and phones',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const BeneficiariesScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          icon: Icons.request_quote_rounded,
          iconColor: const Color(0xFFFBBF24),
          title: 'Request Money',
          subtitle: 'Create payment requests and share lightning invoices',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RequestMoneyScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          icon: Icons.credit_card_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: 'Virtual Travel Cards',
          subtitle: 'USD Visa/Mastercard demo for global subscriptions',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CardsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.darkTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
