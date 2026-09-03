import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/pending/presentation/pending_centre_screen.dart';
import 'package:hanbova_app/features/protected/presentation/protected_screen.dart';
import 'package:intl/intl.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  final _numberFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);

    final totalSats = demoState.totalBalanceSats;
    final availableSats = demoState.availableBalanceSats;
    final protectedSats = demoState.protectedTotalSats;
    final pendingSats = demoState.pendingBalanceSats;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Money & Balances',
          style: TextStyle(
            color: Colors.white,
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
              color: AppColors.primary,
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
                  Text(
                    'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

          // Primary Authoritative Bitcoin Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BITCOIN BALANCE',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: AppColors.primary.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 16, color: AppColors.darkTextSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Authoritative spendable wallet balance ready for instant payments and transfers.',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
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

          // Money in Motion Section
          const Text(
            'Money in motion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Funds locked in protection or awaiting network settlement',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Protected Payments Card
          _buildBreakdownCard(
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
              color: AppColors.darkCardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.pie_chart_outline,
                    size: 20, color: AppColors.darkTextSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        privacy.isBalanceHidden
                            ? 'Portfolio Total: •••••• sats'
                            : 'Portfolio Total: ${_numberFormat.format(totalSats)} sats (≈ ${currency.format(totalSats)})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total combines Available (${_numberFormat.format(availableSats)} sats) + Protected (${_numberFormat.format(protectedSats)} sats) + Pending (${_numberFormat.format(pendingSats)} sats). Only Available is immediately spendable.',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
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

          // Display Currency Selector
          const Text(
            'Reference Display Currency',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Switching display currency updates reference prices across the app and does not convert your underlying Bitcoin.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
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
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.darkCardBackground,
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

  Widget _buildBreakdownCard({
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHidden
                        ? '•••• sats'
                        : '${_numberFormat.format(satsAmount)} sats',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isHidden ? '≈ ••••' : '≈ ${currency.format(satsAmount)}',
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
}
