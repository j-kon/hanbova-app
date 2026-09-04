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
    final colors = context.colors;
    final isDark = context.isDark;
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;
    final identityCountry = market.identityCountryInfo;
    final caps = market.capabilities;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Travel & Spend Hub',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: colors.primary.withValues(alpha: 0.3)),
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
                  style: TextStyle(
                    color: colors.primary,
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
                    colors.surfaceCard,
                    colors.surfaceElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DESTINATION MARKET',
                        style: TextStyle(
                          color: colors.textSecondary,
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
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Currency: ${market.displayCurrency.code} (${spendCountry.defaultCurrency.symbol.trim()}) • Dial: ${spendCountry.dialCode}',
                              style: TextStyle(
                                color: colors.textSecondary,
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
                        color: isDark
                            ? Colors.blueAccent.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_takeoff,
                              color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Traveling from ${identityCountry.flagEmoji} ${identityCountry.name}. Your spending is set to ${spendCountry.name}.',
                              style: TextStyle(
                                color: colors.textPrimary,
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

            Text(
              'TRAVEL SERVICES',
              style: TextStyle(
                color: colors.textSecondary,
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
              subtitle:
                  'Send sats directly to local M-Pesa, Mobile Money & Banks',
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
              badge: caps.airtime ? 'Available' : 'Unavailable',
              badgeColor: caps.airtime ? AppColors.success : Colors.grey,
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
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar,
                          color: colors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Market Rails in ${spendCountry.name} (${spendCountry.code})',
                        style: TextStyle(
                          color: colors.textPrimary,
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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
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
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityChip(String label, bool active) {
    return Builder(builder: (context) {
      final colors = context.colors;
      final isDark = context.isDark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.success.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.success.withValues(alpha: 0.3)
                : (isDark
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.shade300),
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
                color: active
                    ? (isDark ? Colors.white : colors.textPrimary)
                    : colors.textTertiary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showCountryPicker(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
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
              Text(
                'Select Destination Market',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Notice: Your country of residence will not change. Only the destination utilities, local eSIM packages, and spend corridors adapt.',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: CountryInfo.supportedCountries.length,
                  separatorBuilder: (_, __) => Divider(
                    color: colors.divider,
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
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Currency: ${c.defaultCurrency.code} • Dial: ${c.dialCode}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colors.textSecondary,
                      ),
                      onTap: () {
                        ref
                            .read(marketProvider.notifier)
                            .setSpendCountry(c.code);
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
