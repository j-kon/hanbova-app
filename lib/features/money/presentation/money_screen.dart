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

final _numberFormat = NumberFormat('#,##0', 'en_US');

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = context.isDark;

    final currency = ref.watch(currencyProvider);
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);

    final totalSats = demoState.totalBalanceSats;
    final availableSats = demoState.availableBalanceSats;
    final protectedSats = demoState.protectedTotalSats;
    final pendingSats = demoState.pendingBalanceSats;

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

          // Primary Authoritative Bitcoin Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                    : [colors.surfaceCard, colors.surfaceElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: isDark ? 0.3 : 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : AppColors.charcoal.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'BITCOIN BALANCE',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Available to spend',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  privacy.isBalanceHidden
                      ? '•••••• sats'
                      : '${_numberFormat.format(availableSats)} sats',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  privacy.isBalanceHidden
                      ? '≈ ••••••'
                      : '≈ ${currency.format(availableSats)}',
                  style: TextStyle(
                    color: colors.primary.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : colors.surfaceCard.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 16, color: colors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Authoritative spendable wallet balance ready for instant payments and transfers.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Assets Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            subtitle: demoState.isEnabled
                ? '1,800,000 sats available'
                : '${_numberFormat.format(availableSats)} sats available',
            amountDisplay: privacy.isBalanceHidden
                ? '•••• sats'
                : '${_numberFormat.format(availableSats)} sats',
            fiatEstimate: privacy.isBalanceHidden
                ? '••••'
                : '≈ ${currency.format(availableSats)}',
            stateBadge: 'Active',
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
                ? '\$1,250.00 • Stablecoin wallet'
                : 'Stablecoin wallet • Coming soon',
            amountDisplay: demoState.isEnabled
                ? (privacy.isBalanceHidden ? '••••' : '\$1,250.00')
                : '\$0.00',
            fiatEstimate: demoState.isEnabled ? '1,250.00 USDT' : null,
            stateBadge: demoState.isEnabled ? 'Demo' : 'Coming soon',
            badgeColor: demoState.isEnabled
                ? colors.primary
                : const Color(0xFF38BDF8),
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
                ? '\$750.00 • Stablecoin wallet'
                : 'Stablecoin wallet • Coming soon',
            amountDisplay: demoState.isEnabled
                ? (privacy.isBalanceHidden ? '••••' : '\$750.00')
                : '\$0.00',
            fiatEstimate: demoState.isEnabled ? '750.00 USDC' : null,
            stateBadge: demoState.isEnabled ? 'Demo' : 'Coming soon',
            badgeColor: demoState.isEnabled
                ? colors.primary
                : const Color(0xFF38BDF8),
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
            subtitle:
                'Locked in conditional protection (${_numberFormat.format(demoState.protectedWaitingSats)} sats waiting, ${_numberFormat.format(demoState.protectedRefundableSats)} sats refundable)',
            satsAmount: protectedSats,
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
            subtitle: '1 processing payment, 1 uncertain verification',
            satsAmount: pendingSats,
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
                        privacy.isBalanceHidden
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
                        'Total combines Available (${_numberFormat.format(availableSats)} sats) + Protected (${_numberFormat.format(protectedSats)} sats) + Pending (${_numberFormat.format(pendingSats)} sats). Only Available is immediately spendable.',
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
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : colors.textPrimary,
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
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
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
                        fontSize: 15,
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
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHidden
                          ? '•••• sats'
                          : '${_numberFormat.format(satsAmount)} sats',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isHidden ? '≈ ••••' : '≈ ${currency.format(satsAmount)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stateBadge,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountDisplay,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (fiatEstimate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    fiatEstimate,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
