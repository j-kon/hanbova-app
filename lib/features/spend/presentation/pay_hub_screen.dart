import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/market/country_model.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../beneficiaries/presentation/beneficiaries_screen.dart';
import '../../cards/presentation/cards_screen.dart';
import '../../request_money/presentation/request_money_screen.dart';
import 'airtime_flow_screen.dart';
import 'data_bundle_flow_screen.dart';
import 'electricity_flow_screen.dart';
import 'internet_flow_screen.dart';
import 'saved_payments_screen.dart';
import 'tv_subscription_flow_screen.dart';
import 'water_flow_screen.dart';

class PayHubScreen extends ConsumerWidget {
  const PayHubScreen({super.key});

  void _showSpendMarketSelector(BuildContext context, WidgetRef ref) {
    final market = ref.read(marketProvider);
    final countries = CountryInfo.supportedCountries;
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.border),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Active Market',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.flight_takeoff_rounded,
                      color: colors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Switch your spending market to pay local bills while traveling. Your legal country of residence remains unchanged.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ...countries.map((c) {
                final isSelected =
                    c.code.toUpperCase() == market.activeMarket.toUpperCase();
                return ListTile(
                  leading:
                      Text(c.flagEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Currency: ${c.defaultCurrency.code}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: colors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? colors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  onTap: () {
                    ref.read(marketProvider.notifier).setActiveMarket(c.code);
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

  void _showStablecoinInfoModal(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.border),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.token_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stablecoin Rail',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'COMING SOON • PREVIEW',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'USD-pegged stablecoin settlement will be supported once compliant custody and on/off-ramp rails are integrated. No live stablecoin balances or transactions are faked.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Understood',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDemoProviderModal(
      BuildContext context, String providerType, String description) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.border),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$providerType Transfer',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DEMO PREVIEW • COMING SOON',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Direct fiat settlement requires local licensed banking partner integration. No real bank accounts are accessible.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Understood',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final market = ref.watch(marketProvider);
    final activeMarketInfo = market.activeMarketInfo;
    final caps = market.capabilities;
    final hasLocalServices = caps.hasLocalServices;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Pay',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Active Market Switcher Pill
          GestureDetector(
            onTap: () => _showSpendMarketSelector(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activeMarketInfo.flagEmoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    activeMarketInfo.code,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16, color: colors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: hasLocalServices
            ? _buildSupportedMarketPayHub(context, activeMarketInfo, caps)
            : _buildGlobalMarketPayHub(context),
      ),
    );
  }

  // GLOBAL / UNSUPPORTED MARKET PAY HUB (e.g. US, SN without Roam)
  Widget _buildGlobalMarketPayHub(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Send Section
        _buildSectionHeader(
            context, 'Send', 'Peer-to-peer & cross-border transfers'),
        const SizedBox(height: 12),
        _buildGlobalSendGrid(context),
        const SizedBox(height: 28),

        // 2. Wallet Section
        _buildSectionHeader(context, 'Wallet', 'Multi-rail digital balances'),
        const SizedBox(height: 12),
        _buildWalletCards(context),
        const SizedBox(height: 28),

        // 3. Local Services Placeholder
        _buildSectionHeader(
            context, 'Local services', 'Regional utilities and bill payment'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flight_takeoff_rounded,
                        color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activate Roam for Local Services',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local airtime, electricity, and bills are available in supported markets.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Traveling to Nigeria, Kenya, Ghana, Rwanda, Uganda, Tanzania, or South Africa? Activate Roam to unlock everyday bills with instant Bitcoin settlement.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/roam'),
                  icon: const Icon(Icons.travel_explore_rounded, size: 18),
                  label: const Text('Explore Supported Markets'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Safety Reassurance
        _buildSafetyReassurance(context),
        const SizedBox(height: 80),
      ],
    );
  }

  // SUPPORTED LOCAL MARKET PAY HUB (e.g. NG, or KE under Roam)
  Widget _buildSupportedMarketPayHub(
      BuildContext context, CountryInfo activeMarket, MarketCapabilities caps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Send Money Section
        _buildSectionHeader(
            context, 'Send Money', 'Instant peer-to-peer & domestic payouts'),
        const SizedBox(height: 12),
        _buildSupportedSendMoneyGrid(context, caps),
        const SizedBox(height: 24),

        // 2. Recent Section
        _buildSectionHeader(
            context, 'Recent', 'Quick repeat for frequent bills and contacts'),
        const SizedBox(height: 12),
        _buildPayAgainCarousel(context),
        const SizedBox(height: 28),

        // 3. Everyday Bills Section
        if (caps.hasEverydayBills) ...[
          _buildSectionHeader(context, 'Everyday',
              'Instant Bitcoin settlement for local bills'),
          const SizedBox(height: 14),
          _buildServicesGrid(context, caps),
          const SizedBox(height: 28),
        ],

        // 4. Manage Section
        _buildSectionHeader(context, 'Manage',
            'Payment management, beneficiaries, and cards'),
        const SizedBox(height: 12),
        _buildMoreCards(context, caps),
        const SizedBox(height: 28),

        // Safety Reassurance
        _buildSafetyReassurance(context),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSendGrid(BuildContext context) {
    final colors = context.colors;
    final options = [
      {
        'title': 'Bitcoin',
        'subtitle': 'Lightning & On-chain',
        'icon': Icons.bolt_rounded,
        'color': colors.primary,
        'badge': 'Instant',
        'onTap': () => context.push('/send'),
      },
      {
        'title': 'Protected',
        'subtitle': 'Escrow with locktime',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF8B5CF6),
        'badge': 'Buyer Protection',
        'onTap': () => context.push('/protected-send'),
      },
      {
        'title': 'Request Money',
        'subtitle': 'Invoice & claim link',
        'icon': Icons.call_received_rounded,
        'color': const Color(0xFF10B981),
        'badge': 'Peer-to-peer',
        'onTap': () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const RequestMoneyScreen(),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final item = options[index];
        final color = item['color'] as Color;

        return GestureDetector(
          onTap: item['onTap'] as VoidCallback,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['badge'] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCards(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        _buildListTile(
          context,
          icon: Icons.currency_bitcoin,
          iconColor: colors.primary,
          title: 'Bitcoin',
          subtitle: 'Instant Lightning and self-custodial on-chain sats',
          badgeText: 'Live',
          badgeColor: const Color(0xFF10B981),
          onTap: () => context.push('/send'),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          context,
          icon: Icons.shield_moon_outlined,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Cashu',
          subtitle: 'Private ecash mint tokens and offline bearer tokens',
          badgeText: 'Active',
          badgeColor: const Color(0xFF10B981),
          onTap: () => context.push('/send'),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          context,
          icon: Icons.token_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: 'Stablecoin',
          subtitle: 'Compliant USD-pegged stablecoin rail coming soon',
          badgeText: 'Coming soon',
          badgeColor: colors.primary,
          onTap: () => _showStablecoinInfoModal(context),
        ),
      ],
    );
  }

  Widget _buildSupportedSendMoneyGrid(
      BuildContext context, MarketCapabilities caps) {
    final colors = context.colors;
    final sendOptions = [
      {
        'title': 'Bitcoin',
        'subtitle': 'Lightning & On-chain',
        'icon': Icons.bolt_rounded,
        'color': colors.primary,
        'badge': 'Instant',
        'onTap': () => context.push('/send'),
      },
      {
        'title': 'Protected',
        'subtitle': 'Escrow with locktime',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF8B5CF6),
        'badge': 'Buyer Protection',
        'onTap': () => context.push('/protected-send'),
      },
      if (caps.bankPayout) ...[
        {
          'title': 'Bank',
          'subtitle': 'Direct bank account payout',
          'icon': Icons.account_balance_rounded,
          'color': const Color(0xFF38BDF8),
          'badge': 'Local Payout',
          'onTap': () => _showDemoProviderModal(
                context,
                'Bank Payout',
                'Direct fiat payouts to local domestic bank accounts are connected upon licensed provider verification.',
              ),
        },
      ],
      if (caps.mobileMoney) ...[
        {
          'title': 'Mobile Money',
          'subtitle': 'M-Pesa, MTN MoMo, Telecel',
          'icon': Icons.phone_iphone_rounded,
          'color': const Color(0xFF10B981),
          'badge': 'Instant MoMo',
          'onTap': () => _showDemoProviderModal(
                context,
                'Mobile Money',
                'Direct payouts to regional mobile money operators are processed directly from satoshis.',
              ),
        },
      ],
      {
        'title': 'Request Money',
        'subtitle': 'Create payment invoice',
        'icon': Icons.call_received_rounded,
        'color': const Color(0xFFEC4899),
        'badge': 'Peer-to-peer',
        'onTap': () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const RequestMoneyScreen(),
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
        childAspectRatio: 1.5,
      ),
      itemCount: sendOptions.length,
      itemBuilder: (context, index) {
        final item = sendOptions[index];
        final color = item['color'] as Color;

        return GestureDetector(
          onTap: item['onTap'] as VoidCallback,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['badge'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayAgainCarousel(BuildContext context) {
    final colors = context.colors;
    final recentItems = [
      {
        'title': 'Mom\'s MTN',
        'subtitle': 'Airtime top-up',
        'amount': '2,000 sats',
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
        'amount': '10,000 sats',
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
        'amount': '15,700 sats',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFA78BFA),
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const TvSubscriptionFlowScreen()),
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
          final color = item['color'] as Color;

          return GestureDetector(
            onTap: item['action'] as VoidCallback,
            child: Container(
              width: 155,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
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
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['amount'] as String,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
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
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
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

  Widget _buildServicesGrid(BuildContext context, MarketCapabilities caps) {
    final colors = context.colors;
    final services = <Map<String, dynamic>>[];

    if (caps.airtime) {
      services.add({
        'title': 'Airtime',
        'desc': 'Instant top-up',
        'icon': Icons.phone_android_rounded,
        'color': colors.primary,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AirtimeFlowScreen()),
            ),
      });
    }

    if (caps.data) {
      services.add({
        'title': 'Data Bundles',
        'desc': 'Daily, weekly, monthly',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF38BDF8),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const DataBundleFlowScreen()),
            ),
      });
    }

    if (caps.electricity) {
      services.add({
        'title': 'Electricity',
        'desc': 'Prepaid token generator',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFFFBBF24),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ElectricityFlowScreen()),
            ),
      });
    }

    if (caps.tv) {
      services.add({
        'title': 'TV Cables',
        'desc': 'Digital satellite plans',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFA78BFA),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const TvSubscriptionFlowScreen()),
            ),
      });
    }

    if (caps.internet) {
      services.add({
        'title': 'Internet',
        'desc': 'Fibre & 4G LTE broadband',
        'icon': Icons.router_rounded,
        'color': const Color(0xFF34D399),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const InternetFlowScreen()),
            ),
      });
    }

    if (caps.water) {
      services.add({
        'title': 'Water Bills',
        'desc': 'Municipal utilities',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF06B6D4),
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WaterFlowScreen()),
            ),
      });
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        final color = item['color'] as Color;

        return GestureDetector(
          onTap: item['onTap'] as VoidCallback,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 22,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  style: TextStyle(
                    color: colors.textSecondary,
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

  Widget _buildMoreCards(BuildContext context, MarketCapabilities caps) {
    return Column(
      children: [
        _buildListTile(
          context,
          icon: Icons.bookmark_added_rounded,
          iconColor: context.colors.primary,
          title: 'Saved Payments',
          subtitle: 'Manage saved meters, TV accounts, and recurring bills',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const SavedPaymentsScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _buildListTile(
          context,
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: 'Beneficiaries',
          subtitle: 'Saved peer recipients, lightning addresses, and phones',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const BeneficiariesScreen()),
          ),
        ),
        if (caps.virtualCards) ...[
          const SizedBox(height: 10),
          _buildListTile(
            context,
            icon: Icons.credit_card_rounded,
            iconColor: const Color(0xFFA78BFA),
            title: 'Cards',
            subtitle: 'USD Visa/Mastercard demo for global subscriptions',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CardsScreen()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
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
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (badgeColor ?? colors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor ?? colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: colors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyReassurance(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Bitcoin Backed',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hanbova holds zero local fiat balances. Local airtime, electricity, and utilities are settled on-demand directly from your satoshis.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
