import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/market/country_model.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/spend/presentation/spend_screen.dart';
import 'package:hanbova_app/features/travel/presentation/esim_screen.dart';
import 'package:hanbova_app/features/travel/presentation/payouts_and_cards_sheet.dart';

class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;
    final identityCountry = market.identityCountryInfo;
    final caps = market.capabilities;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Travel & Spend Hub',
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spendCountry.flagEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  market.displayCurrency.code,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
            // Destination Market Selector Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkSurfaceCard,
                    AppColors.darkSurfaceCard.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DESTINATION MARKET',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCountryPicker(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        spendCountry.flagEmoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spendCountry.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Currency: ${market.displayCurrency.code} (${spendCountry.defaultCurrency.symbol.trim()}) • Dial: ${spendCountry.dialCode}',
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (market.identityCountry != market.spendCountry) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_takeoff,
                              color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Traveling from ${identityCountry.flagEmoji} ${identityCountry.name}. Your spending is set to ${spendCountry.name}.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'TRAVEL SERVICES',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // 1. eSIM & Roaming
            _buildServiceCard(
              context: context,
              icon: Icons.sim_card_outlined,
              iconBg: Colors.purple.withValues(alpha: 0.2),
              iconColor: Colors.purpleAccent,
              title: 'Connectivity (eSIM)',
              subtitle: 'High-speed local & regional mobile data bundles',
              badge: caps.esim ? 'Available' : 'Unavailable',
              badgeColor: caps.esim ? AppColors.success : Colors.grey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EsimScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // 2. Local Payouts (M-Pesa / Bank)
            _buildServiceCard(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              iconBg: Colors.green.withValues(alpha: 0.2),
              iconColor: Colors.greenAccent,
              title: 'Local Cash Payouts',
              subtitle: 'Send sats directly to local M-Pesa, Mobile Money & Banks',
              badge: caps.payouts ? 'Available' : 'Corridor Closed',
              badgeColor: caps.payouts ? AppColors.success : Colors.grey,
              onTap: () {
                PayoutsAndCardsSheet.showPayouts(context, spendCountry.code);
              },
            ),

            const SizedBox(height: 12),

            // 3. Virtual Cards
            _buildServiceCard(
              context: context,
              icon: Icons.credit_card_outlined,
              iconBg: Colors.orange.withValues(alpha: 0.2),
              iconColor: Colors.orangeAccent,
              title: 'Virtual Cards',
              subtitle: 'Instant USD Visa & Mastercard funded with Bitcoin',
              badge: caps.cards ? 'Eligible' : 'Restricted',
              badgeColor: caps.cards ? AppColors.success : Colors.grey,
              onTap: () {
                PayoutsAndCardsSheet.showCards(context, spendCountry.code);
              },
            ),

            const SizedBox(height: 12),

            // 4. Everyday Spend (Airtime & Utilities)
            _buildServiceCard(
              context: context,
              icon: Icons.bolt_outlined,
              iconBg: Colors.amber.withValues(alpha: 0.2),
              iconColor: Colors.amberAccent,
              title: 'Everyday Spend & Bills',
              subtitle: 'Pay airtime, electricity tokens, water, TV & internet',
              badge: 'Active in ${spendCountry.code}',
              badgeColor: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SpendScreen()),
                );
              },
            ),

            const SizedBox(height: 28),

            // Live Capabilities Pill Matrix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Market Rails in ${spendCountry.name} (${spendCountry.code})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCapabilityChip('Airtime', caps.airtime),
                      _buildCapabilityChip('Mobile Data', caps.data),
                      _buildCapabilityChip('Electricity', caps.electricity),
                      _buildCapabilityChip('Water', caps.water),
                      _buildCapabilityChip('Pay TV', caps.tv),
                      _buildCapabilityChip('Internet', caps.internet),
                      _buildCapabilityChip('eSIM', caps.esim),
                      _buildCapabilityChip('M-Pesa / MoMo', caps.mobileMoney),
                      _buildCapabilityChip('Bank Payouts', caps.payouts),
                      _buildCapabilityChip('Virtual Cards', caps.cards),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.darkTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: active ? AppColors.success : Colors.grey,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Destination Market',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Available services and payment corridors adapt automatically.',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: CountryInfo.supportedCountries.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.darkBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = CountryInfo.supportedCountries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        c.flagEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Currency: ${c.defaultCurrency.code} • Dial: ${c.dialCode}',
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
                        ref.read(marketProvider.notifier).setSpendCountry(c.code);
                        Navigator.of(ctx).pop();
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
}
