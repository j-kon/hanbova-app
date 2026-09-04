import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/security/privacy_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';

class BitcoinDetailScreen extends ConsumerWidget {
  const BitcoinDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = context.isDark;
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);
    final currency = ref.watch(currencyProvider);
    final cashuBalance = ref.watch(cashuBalanceProvider);

    final int availableSats = demoState.isEnabled
        ? demoState.availableBalanceSats
        : cashuBalance.maybeWhen(
            data: (w) => w.spendableSats,
            orElse: () => 0,
          );

    final int protectedSats = demoState.isEnabled
        ? demoState.protectedTotalSats
        : cashuBalance.maybeWhen(
            data: (w) => w.lockedEscrowSats,
            orElse: () => 0,
          );

    final int pendingSats = demoState.isEnabled
        ? demoState.pendingBalanceSats
        : 0;

    final int totalSats = availableSats + protectedSats;

    // Filter bitcoin transactions
    final allTxs = demoState.isEnabled
        ? demoState.demoTransactions
        : ref.watch(transactionsProvider);
    final btcTxs = allTxs.where((tx) {
      return tx.type == TransactionType.bitcoinReceived ||
          tx.type == TransactionType.bitcoinSent ||
          tx.type == TransactionType.instantReceive ||
          tx.type == TransactionType.instantSend ||
          tx.type == TransactionType.protectedPayment ||
          tx.type == TransactionType.protectedSend ||
          tx.type == TransactionType.protectedClaim ||
          tx.type == TransactionType.protectedRefund ||
          tx.type == TransactionType.btcToUsdtConversion ||
          tx.type == TransactionType.btcToUsdcConversion ||
          tx.type == TransactionType.usdtToBtcConversion ||
          tx.type == TransactionType.usdcToBtcConversion;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF7931A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_bitcoin_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Bitcoin (BTC)',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              privacy.isBalanceHidden
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () =>
                ref.read(privacyProvider.notifier).toggleBalanceHidden(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          if (demoState.isEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
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
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Total Bitcoin Balance Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                    : [colors.surfaceCard, colors.surfaceElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: colors.primary.withValues(alpha: isDark ? 0.3 : 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL BITCOIN',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  privacy.isBalanceHidden
                      ? '••••••'
                      : currency.format(totalSats),
                  style: AppTypography.displaySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  privacy.isBalanceHidden
                      ? '•••• sats'
                      : '${Formatters.formatSats(totalSats)} sats',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Available, Protected, Pending Breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildBreakdownCol(
                        'Available',
                        availableSats,
                        colors.textPrimary,
                        privacy.isBalanceHidden,
                      ),
                    ),
                    Expanded(
                      child: _buildBreakdownCol(
                        'Protected',
                        protectedSats,
                        colors.protected,
                        privacy.isBalanceHidden,
                      ),
                    ),
                    Expanded(
                      child: _buildBreakdownCol(
                        'Pending',
                        pendingSats,
                        colors.warning,
                        privacy.isBalanceHidden,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions: Send, Receive, Convert
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Send',
                  color: colors.primary,
                  onTap: () => context.push('/send'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  context,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Receive',
                  color: const Color(0xFF10B981),
                  onTap: () => UnifiedDepositSheet.show(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  label: 'Convert',
                  color: const Color(0xFF38BDF8),
                  onTap: () => context.push('/convert'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Recent Activity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Bitcoin Activity',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (btcTxs.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  'No recent Bitcoin transactions',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            ...btcTxs.take(5).map((tx) => _buildTxTile(context, tx, colors)),
        ],
      ),
    );
  }

  Widget _buildBreakdownCol(
      String label, int sats, Color color, bool isHidden) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isHidden ? '••••' : Formatters.formatSats(sats),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxTile(
      BuildContext context, TransactionModel tx, HanbovaColors colors) {
    final isOut = tx.isOutgoing;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isOut
                ? colors.danger.withValues(alpha: 0.1)
                : const Color(0xFF10B981).withValues(alpha: 0.1),
            child: Icon(
              isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isOut ? colors.danger : const Color(0xFF10B981),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  tx.recipientOrSender,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isOut ? '-' : '+'}${Formatters.formatSats(tx.amountSats)} sats',
            style: TextStyle(
              color: isOut ? colors.textPrimary : const Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
