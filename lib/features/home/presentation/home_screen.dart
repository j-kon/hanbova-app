import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/security/privacy_provider.dart';
import 'home_balance_card.dart';
import '../../transactions/presentation/activity_transaction_tile.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/sync/wallet_sync_coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../security/presentation/mainnet_safety_dialog.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/market/country_model.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/widgets/hanbova_rate_card.dart';
import '../../../core/rates/hanbova_rate_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../request_money/presentation/request_money_screen.dart';

/// Data model representing an item in the Home action rail.
/// Allows dynamic and future user-customizable ordering of quick actions.
class ActionRailItemData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionRailItemData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final isBalanceVisible = !ref.watch(privacyProvider).isBalanceHidden;
    final currency = ref.watch(currencyProvider);
    final transactions = ref.watch(transactionsProvider);
    final demoState = ref.watch(demoModeProvider);
    final market = ref.watch(marketProvider);
    final cashuBalanceAsync = ref.watch(cashuBalanceProvider);
    final cashuBalance = cashuBalanceAsync.valueOrNull ??
        const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
    final String? balanceStatus = !demoState.isEnabled &&
            (cashuBalanceAsync.isLoading ||
                cashuBalanceAsync.hasError ||
                !cashuBalanceAsync.hasValue)
        ? (cashuBalanceAsync.hasError ? 'Unavailable' : 'Updating…')
        : null;

    final incomingClaimable = transactions
        .where((t) =>
            t.type == TransactionType.protectedClaim &&
            t.status == TransactionStatus.claimable)
        .toList();
    final protectedSats = demoState.isEnabled
        ? demoState.protectedTotalSats
        : cashuBalance.lockedEscrowSats;
    final spendableSats = demoState.isEnabled
        ? demoState.availableBalanceSats
        : cashuBalance.spendableSats;

    final profile = ref.watch(profileProvider);
    final residence = profile.residenceCountryInfo;
    final greeting = _getGreeting();
    final displayName = profile.firstName.isNotEmpty
        ? profile.firstName
        : (user?.firstName.isNotEmpty == true ? user!.firstName : 'Jaykon');

    final currentNetwork = ref.watch(networkEnvironmentProvider);
    final netConfig = ref.watch(activeNetworkConfigProvider);
    final isMainnet = currentNetwork == HanbovaNetwork.mainnet;

    final actionRailItems = _getActionRailItems(context, colors, market);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashuBalanceProvider);
            ref.read(hanbovaRateProvider.notifier).refresh();
            try {
              await ref.read(walletSyncCoordinatorProvider)?.syncNow();
            } catch (_) {}
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (transactions.isStale) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      transactions.syncMessage ??
                          'Showing saved activity while offline.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // 1. Header (User profile avatar, Greeting, Actions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  colors.primary.withValues(alpha: 0.15),
                              child: Text(
                                profile.initials,
                                style: AppTypography.titleMedium.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting, $displayName',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    residence.name,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Notifications',
                          icon: Icon(Icons.notifications_none_rounded,
                              color: colors.textPrimary),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Demo Banner (if demo active)
                if (ref.watch(demoModeProvider).isEnabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.xsRadius,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: colors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                            style: AppTypography.caption.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2.5 Active Roam Compact Home Indicator
                if (market.isRoamActive) ...[
                  InkWell(
                    onTap: () => context.push('/roam'),
                    borderRadius: AppRadius.smRadius,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: AppRadius.smRadius,
                        border: Border.all(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            market.activeMarketInfo.flagEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${market.activeMarketInfo.flagEmoji} Roam active • ${market.activeMarketInfo.name}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                HomeBalanceCard(
                  amount: isBalanceVisible
                      ? currency.format(spendableSats)
                      : '••••••',
                  sats: isBalanceVisible
                      ? '${Formatters.formatSatsNumber(spendableSats)} ${isMainnet ? "sats" : "test sats"}'
                      : '•••• sats',
                  protectedAmount: balanceStatus ??
                      (isBalanceVisible
                          ? Formatters.formatSats(protectedSats)
                          : '••••'),
                  pendingAmount: !demoState.isEnabled
                      ? 'Check status'
                      : isBalanceVisible
                          ? Formatters.formatSats(demoState.pendingBalanceSats)
                          : '••••',
                  environmentLabel: demoState.isEnabled
                      ? ''
                      : isMainnet
                          ? (netConfig.isPilot
                              ? 'Pilot · Real Bitcoin · 10,000 sats limit'
                              : 'Mainnet locked')
                          : 'Test mode · No monetary value',
                  isHidden: !isBalanceVisible,
                  isLoading:
                      !demoState.isEnabled && cashuBalanceAsync.isLoading,
                  hasError: !demoState.isEnabled && cashuBalanceAsync.hasError,
                  onRetry: () => ref.invalidate(cashuBalanceProvider),
                  onToggleVisibility: () =>
                      ref.read(privacyProvider.notifier).toggleBalanceHidden(),
                  onProtected: () => context.push('/protected'),
                  onPending: () => context.push('/pending'),
                  onEnvironment: () => MainnetSafetyDialog.show(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  onTap: () => context.go('/money'),
                  leading: Icon(Icons.account_balance_wallet_outlined,
                      color: colors.textSecondary),
                  title: Text('View Money',
                      style: AppTypography.bodyMedium
                          .copyWith(color: colors.textPrimary)),
                  subtitle: Text(
                      !isBalanceVisible
                          ? 'USDT •••• · USDC ••••'
                          : demoState.isEnabled
                              ? 'Other: USDT \$1,250 • USDC \$750'
                              : 'Other assets · Coming soon',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary)),
                  trailing:
                      Icon(Icons.chevron_right, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                // Keep the four main payment actions visible at phone widths.
                LayoutBuilder(builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final columns =
                      largeText || constraints.maxWidth < 300 ? 2 : 4;
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final item in actionRailItems.take(4))
                      SizedBox(
                          width: (constraints.maxWidth - 8 * (columns - 1)) /
                              columns,
                          child: _buildActionRailItem(context,
                              icon: item.icon,
                              label: item.label,
                              color: item.color,
                              onTap: item.onTap)),
                  ]);
                }),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final item in actionRailItems.skip(4))
                    TextButton.icon(
                      key: Key('action_rail_${item.label.toLowerCase()}'),
                      onPressed: item.onTap,
                      icon: Icon(item.icon, size: 18),
                      label: Text(item.label),
                      style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          minimumSize: const Size(48, 48)),
                    ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // 3.4 Live Hanbova Platform Rate
                const HanbovaRateCard(),
                const SizedBox(height: AppSpacing.md),

                // 3.5 Quick Pay Services (Rendered only when active market supports everyday bills)
                if (market.capabilities.hasEverydayBills) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Quick Pay',
                              style: AppTypography.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/pay'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text('All Bills'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (market.capabilities.airtime) ...[
                                _buildQuickPayIcon(
                                  context,
                                  icon: Icons.phone_android_rounded,
                                  label: 'Airtime',
                                  color: AppColors.primary,
                                  onTap: () => context.push('/pay/airtime'),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (market.capabilities.data) ...[
                                _buildQuickPayIcon(
                                  context,
                                  icon: Icons.wifi_rounded,
                                  label: 'Data',
                                  color: const Color(0xFF38BDF8),
                                  onTap: () => context.push('/pay/data'),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (market.capabilities.electricity) ...[
                                _buildQuickPayIcon(
                                  context,
                                  icon: Icons.electric_bolt_rounded,
                                  label: 'Electricity',
                                  color: const Color(0xFFFBBF24),
                                  onTap: () => context.push('/pay/electricity'),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (market.capabilities.water) ...[
                                _buildQuickPayIcon(
                                  context,
                                  icon: Icons.water_drop_rounded,
                                  label: 'Water',
                                  color: const Color(0xFF06B6D4),
                                  onTap: () => context.push('/pay/water'),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (market.capabilities.tv) ...[
                                _buildQuickPayIcon(
                                  context,
                                  icon: Icons.tv_rounded,
                                  label: 'TV',
                                  color: const Color(0xFFA78BFA),
                                  onTap: () => context.push('/pay/tv'),
                                ),
                                const SizedBox(width: 12),
                              ],
                              _buildQuickPayIcon(
                                context,
                                icon: Icons.more_horiz_rounded,
                                label: 'More',
                                color: const Color(0xFF94A3B8),
                                onTap: () => context.go('/pay'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 4. Needs Attention Hub (High-priority actionable items only)
                // Card 1: Refund Available
                if (demoState.isEnabled &&
                    demoState.protectedRefundableSats > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF06B6D4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Protected Refund Ready',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${Formatters.formatSats(demoState.protectedRefundableSats)} expired locktime can be claimed back.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Refund',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 2: Payment Uncertain Notice
                if (transactions
                        .any((t) => t.status == TransactionStatus.uncertain) ||
                    (demoState.isEnabled &&
                        demoState.demoTransactions.any((t) =>
                            t.status == TransactionStatus.uncertain))) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top_rounded,
                              color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Processing (Uncertain)',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Checking status with biller. Please don\'t pay again yet.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Status',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 3: Incoming Protected Payment Received
                if (incomingClaimable.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.incoming.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: colors.incoming.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.incoming,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Protected Payment Received!',
                                style: AppTypography.titleSmall.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.incoming.withValues(alpha: 0.2),
                                borderRadius: AppRadius.xsRadius,
                              ),
                              child: Text(
                                '${incomingClaimable.length} Waiting',
                                style: AppTypography.caption.copyWith(
                                  color: colors.incoming,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isBalanceVisible
                              ? '${Formatters.formatSats(incomingClaimable.first.amountSats)} waiting from ${incomingClaimable.first.recipientOrSender}'
                              : 'Payment waiting from ${incomingClaimable.first.recipientOrSender}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/claim');
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: const Text('Claim to Wallet Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.incoming,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 4: eSIM Low Data Alert
                if (demoState.isEnabled) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sim_card_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'eSIM Low Data (250 MB left)',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kenya Traveler 3 GB eSIM is running low.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/travel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Top Up',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. Compact Financial Snapshot (Money & Insights shortcut)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pie_chart_outline_rounded,
                            size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Snapshot',
                              style: AppTypography.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Monthly spending & bitcoin insights',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push('/insights'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Insights',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 6. Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Recent Activity',
                        style: AppTypography.titleMedium
                            .copyWith(color: colors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/activity'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Recent Activity List
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: colors.textTertiary, size: 36),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No transactions yet',
                            style: AppTypography.titleSmall
                                .copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your Hanbova payments will appear here.',
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...transactions.take(4).map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: ActivityTransactionTile(
                              transaction: tx,
                              currency: currency,
                              hideAmounts: !isBalanceVisible,
                              onTap: () =>
                                  context.push('/activity/details', extra: tx)),
                        ),
                      ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionCatalogueSheet(BuildContext context) {
    final colors = context.colors;
    final items = [
      {
        'title': 'Data',
        'subtitle': 'Internet data bundles',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF38BDF8),
        'onTap': () {
          Navigator.pop(context);
          context.push('/pay/data');
        },
      },
      {
        'title': 'Electricity',
        'subtitle': 'Prepaid meter tokens',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFFFBBF24),
        'onTap': () {
          Navigator.pop(context);
          context.push('/pay/electricity');
        },
      },
      {
        'title': 'TV',
        'subtitle': 'Cable & satellite TV',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFA78BFA),
        'onTap': () {
          Navigator.pop(context);
          context.push('/pay/tv');
        },
      },
      {
        'title': 'Internet',
        'subtitle': 'Broadband & Wi-Fi',
        'icon': Icons.router_rounded,
        'color': const Color(0xFF34D399),
        'onTap': () {
          Navigator.pop(context);
          context.push('/pay/internet');
        },
      },
      {
        'title': 'Water',
        'subtitle': 'Utility water bills',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF06B6D4),
        'onTap': () {
          Navigator.pop(context);
          context.push('/pay/water');
        },
      },
      {
        'title': 'Saved Payments',
        'subtitle': 'Frequent meters & accounts',
        'icon': Icons.bookmark_border_rounded,
        'color': const Color(0xFFEC4899),
        'onTap': () {
          Navigator.pop(context);
          context.push('/saved-payments');
        },
      },
      {
        'title': 'Beneficiaries',
        'subtitle': 'Contacts & payment details',
        'icon': Icons.people_outline_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () {
          Navigator.pop(context);
          context.push('/beneficiaries');
        },
      },
      {
        'title': 'Cards',
        'subtitle': 'Virtual Visa & Mastercard',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () {
          Navigator.pop(context);
          context.push('/cards');
        },
      },
      {
        'title': 'Roam',
        'subtitle': 'Spend like a local when away',
        'icon': Icons.travel_explore_rounded,
        'color': const Color(0xFFF97316),
        'onTap': () {
          Navigator.pop(context);
          context.push('/roam');
        },
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Action Catalogue',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final color = item['color'] as Color;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'] as IconData,
                              color: color, size: 20),
                        ),
                        title: Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: item['onTap'] as VoidCallback,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ActionRailItemData> _getActionRailItems(
      BuildContext context, HanbovaColors colors, UserCountryContext market) {
    return [
      ActionRailItemData(
        id: 'send',
        label: 'Send',
        icon: Icons.arrow_upward_rounded,
        color: colors.primary,
        onTap: () => context.push('/send'),
      ),
      ActionRailItemData(
        id: 'receive',
        label: 'Receive',
        icon: Icons.arrow_downward_rounded,
        color: const Color(0xFF10B981),
        onTap: () => UnifiedDepositSheet.show(context),
      ),
      ActionRailItemData(
        id: 'protected',
        label: 'Protected',
        icon: Icons.shield_outlined,
        color: colors.protected,
        onTap: () => context.push('/protected-send'),
      ),
      ActionRailItemData(
        id: 'scan',
        label: 'Scan',
        icon: Icons.qr_code_scanner_rounded,
        color: const Color(0xFF38BDF8),
        onTap: () => context.push('/scan'),
      ),
      ActionRailItemData(
        id: 'request',
        label: 'Request',
        icon: Icons.call_received_rounded,
        color: const Color(0xFFEC4899),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const RequestMoneyScreen(),
        ),
      ),
      ActionRailItemData(
        id: 'convert',
        label: 'Convert',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF38BDF8),
        onTap: () => context.push('/convert'),
      ),
      if (market.capabilities.airtime)
        ActionRailItemData(
          id: 'airtime',
          label: 'Airtime',
          icon: Icons.phone_android_rounded,
          color: AppColors.primary,
          onTap: () => context.push('/pay/airtime'),
        ),
      ActionRailItemData(
        id: 'more',
        label: 'More',
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFF94A3B8),
        onTap: () => _showActionCatalogueSheet(context),
      ),
    ];
  }

  Widget _buildActionRailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      key: Key('action_rail_${label.toLowerCase()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPayIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
