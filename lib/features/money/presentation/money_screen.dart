import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/pending/presentation/pending_centre_screen.dart';
import 'package:hanbova_app/features/protected/presentation/protected_screen.dart';
import 'package:intl/intl.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/widgets/hanbova_rate_card.dart';
import '../../home/presentation/home_balance_card.dart';

final _numberFormat = NumberFormat('#,##0', 'en_US');

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    final currency = ref.watch(currencyProvider);
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);

    final walletBalance = ref.watch(cashuBalanceProvider);
    final String? balanceStatus = !demoState.isEnabled &&
            (walletBalance.isLoading ||
                walletBalance.hasError ||
                !walletBalance.hasValue)
        ? (walletBalance.hasError ? 'Balance unavailable' : 'Updating balance…')
        : null;
    final availableSats = demoState.isEnabled
        ? demoState.availableBalanceSats
        : walletBalance.valueOrNull?.spendableSats ?? 0;
    final protectedSats = demoState.isEnabled
        ? demoState.protectedTotalSats
        : walletBalance.valueOrNull?.lockedEscrowSats ?? 0;
    final pendingSats = demoState.isEnabled ? demoState.pendingBalanceSats : 0;
    final totalSats = demoState.isEnabled
        ? demoState.totalBalanceSats
        : availableSats + protectedSats;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Money & Balances',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                privacy.isBalanceHidden ? 'Show balances' : 'Hide balances',
            icon: Icon(
              privacy.isBalanceHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: colors.primary,
            ),
            onPressed: () =>
                ref.read(privacyProvider.notifier).toggleBalanceHidden(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Demo Banner
          if (demoState.isEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
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

          HomeBalanceCard(
            title: 'Your Bitcoin balance',
            showMotion: false,
            amount: privacy.isBalanceHidden
                ? '•••••• sats'
                : '${_numberFormat.format(availableSats)} sats',
            sats: privacy.isBalanceHidden
                ? '≈ ••••••'
                : '≈ ${currency.format(availableSats)}',
            protectedAmount: '',
            pendingAmount: '',
            environmentLabel:
                demoState.isEnabled ? '' : 'Available in your wallet',
            isHidden: privacy.isBalanceHidden,
            isLoading: !demoState.isEnabled && walletBalance.isLoading,
            hasError: !demoState.isEnabled && walletBalance.hasError,
            onRetry: () => ref.invalidate(cashuBalanceProvider),
            onToggleVisibility: () =>
                ref.read(privacyProvider.notifier).toggleBalanceHidden(),
            onProtected: () {},
            onPending: () {},
          ),
          const SizedBox(height: 16),

          // Live Hanbova Platform Settlement Rate
          const HanbovaRateCard(),
          const SizedBox(height: 24),

          // Assets Section
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Assets',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (demoState.isEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEMO BALANCES',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bitcoin Asset Card
          _buildAssetRow(
            context,
            icon: Icons.currency_bitcoin_rounded,
            iconColor: const Color(0xFFF7931A),
            name: 'Bitcoin',
            subtitle: balanceStatus == null
                ? 'Available for payments'
                : 'Check your wallet connection',
            amountDisplay: balanceStatus ??
                (privacy.isBalanceHidden
                    ? '•••• sats'
                    : '${_numberFormat.format(availableSats)} sats'),
            fiatEstimate: balanceStatus != null
                ? null
                : privacy.isBalanceHidden
                    ? '••••'
                    : '≈ ${currency.format(availableSats)}',
            stateBadge: balanceStatus == null
                ? 'Active'
                : walletBalance.hasError
                    ? 'Unavailable'
                    : 'Updating',
            badgeColor: const Color(0xFF10B981),
            onTap: () => context.push('/money/bitcoin'),
            colors: colors,
          ),
          const SizedBox(height: 10),

          // USDT Asset Card
          _buildAssetRow(
            context,
            icon: Icons.attach_money_rounded,
            iconColor: const Color(0xFF26A17B),
            name: 'USDT',
            subtitle: demoState.isEnabled
                ? 'Sample stablecoin balance'
                : 'Coming soon',
            amountDisplay: demoState.isEnabled
                ? (privacy.isBalanceHidden ? '••••' : '\$1,250.00')
                : '\$0.00',
            fiatEstimate: demoState.isEnabled && !privacy.isBalanceHidden
                ? '1,250.00 USDT'
                : null,
            stateBadge: demoState.isEnabled ? 'Demo' : 'Coming soon',
            badgeColor:
                demoState.isEnabled ? colors.primary : const Color(0xFF38BDF8),
            onTap: () => context.push('/money/usdt'),
            colors: colors,
          ),
          const SizedBox(height: 10),

          // USDC Asset Card
          _buildAssetRow(
            context,
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFF2775CA),
            name: 'USDC',
            subtitle: demoState.isEnabled
                ? 'Sample stablecoin balance'
                : 'Coming soon',
            amountDisplay: demoState.isEnabled
                ? (privacy.isBalanceHidden ? '••••' : '\$750.00')
                : '\$0.00',
            fiatEstimate: demoState.isEnabled && !privacy.isBalanceHidden
                ? '750.00 USDC'
                : null,
            stateBadge: demoState.isEnabled ? 'Demo' : 'Coming soon',
            badgeColor:
                demoState.isEnabled ? colors.primary : const Color(0xFF38BDF8),
            onTap: () => context.push('/money/usdc'),
            colors: colors,
          ),

          const SizedBox(height: 24),

          // Money in Motion Section
          Text(
            'Money in motion',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Funds locked in protection or awaiting network settlement',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Protected Payments Card
          _buildBreakdownCard(
            context,
            title: 'Protected payments',
            subtitle: 'Waiting for a claim or eligible for a refund',
            satsAmount: protectedSats,
            amountStatus: balanceStatus,
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF38BDF8),
            actionLabel: 'View Protected',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProtectedScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // Pending & In Flight Card
          _buildBreakdownCard(
            context,
            title: 'Pending',
            subtitle: demoState.isEnabled
                ? 'Sample payments awaiting confirmation'
                : 'Check payments awaiting confirmation',
            satsAmount: pendingSats,
            amountStatus: demoState.isEnabled ? null : 'Check payment status',
            currency: currency,
            isHidden: privacy.isBalanceHidden,
            icon: Icons.hourglass_top_rounded,
            iconColor: const Color(0xFFF59E0B),
            actionLabel: 'Pending Centre',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PendingCentreScreen()),
              );
            },
          ),

          const SizedBox(height: 14),

          // Portfolio Reference Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.pie_chart_outline,
                    size: 20, color: colors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balanceStatus != null
                            ? 'Portfolio Total: $balanceStatus'
                            : privacy.isBalanceHidden
                                ? 'Portfolio Total: •••••• sats'
                                : 'Portfolio Total: ${_numberFormat.format(totalSats)} sats (≈ ${currency.format(totalSats)})',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Only your available balance can be spent. Protected funds are shown separately.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Financial Reports & Insights Section
          Text(
            'Insights & Statements',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analytics, spending trends, network fees, and statements',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/insights'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insights_rounded,
                            color: colors.primary, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          'Insights',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Spend patterns & fees',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/statements'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined,
                            color: Color(0xFF10B981), size: 22),
                        const SizedBox(height: 8),
                        Text(
                          'Statements',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly PDF exports',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Display Currency Selector
          Text(
            'Reference Display Currency',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switching display currency updates reference prices across the app and does not convert your underlying Bitcoin.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: FiatCurrency.values.map((fc) {
              final isSelected = fc == currency;
              return ChoiceChip(
                label: Text(
                  '${fc.code} (${fc.symbol.trim()})',
                  style: TextStyle(
                    color: isSelected ? AppColors.charcoal : colors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.border,
                ),
                onSelected: (val) {
                  if (val) {
                    ref.read(currencyProvider.notifier).setCurrency(fc);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int satsAmount,
    String? amountStatus,
    required FiatCurrency currency,
    required bool isHidden,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: colors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Text(
              amountStatus ??
                  (isHidden
                      ? '•••• sats'
                      : '${_numberFormat.format(satsAmount)} sats'),
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600)),
          if (amountStatus == null) ...[
            const SizedBox(height: 4),
            Text(isHidden ? '≈ ••••' : '≈ ${currency.format(satsAmount)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ]));
  }

  Widget _buildAssetRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String name,
    required String subtitle,
    required String amountDisplay,
    String? fiatEstimate,
    required String stateBadge,
    required Color badgeColor,
    required VoidCallback onTap,
    required HanbovaColors colors,
  }) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: colors.surfaceElevated, shape: BoxShape.circle),
                  child: Icon(icon, color: colors.textPrimary, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(stateBadge,
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12))),
                        ]),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    Text(amountDisplay,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    if (fiatEstimate != null) ...[
                      const SizedBox(height: 4),
                      Text(fiatEstimate,
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12)),
                    ],
                  ])),
              Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
            ])));
  }
}
