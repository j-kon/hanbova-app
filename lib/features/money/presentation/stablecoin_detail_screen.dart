import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/security/privacy_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/domain/asset_model.dart';

class StablecoinDetailScreen extends ConsumerWidget {
  final AssetType asset;

  const StablecoinDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = context.isDark;
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);

    final isUSDT = asset == AssetType.usdt;
    final double totalBalance = demoState.isEnabled
        ? (isUSDT ? demoState.demoUsdtBalance : demoState.demoUsdcBalance)
        : 0.0;
    final double availableBalance = totalBalance;
    const double pendingBalance = 0.0;

    final featureState = demoState.isEnabled
        ? AssetFeatureState.active
        : AssetFeatureState.comingSoon;

    // Filter transactions for this stablecoin
    final allTxs = demoState.isEnabled
        ? demoState.demoTransactions
        : ref.watch(transactionsProvider);
    final stablecoinTxs = allTxs.where((tx) {
      if (isUSDT) {
        return tx.type == TransactionType.usdtSent ||
            tx.type == TransactionType.usdtReceived ||
            tx.type == TransactionType.btcToUsdtConversion ||
            tx.type == TransactionType.usdtToBtcConversion ||
            tx.type == TransactionType.usdtToUsdcConversion ||
            tx.type == TransactionType.usdcToUsdtConversion;
      } else {
        return tx.type == TransactionType.usdcSent ||
            tx.type == TransactionType.usdcReceived ||
            tx.type == TransactionType.btcToUsdcConversion ||
            tx.type == TransactionType.usdcToBtcConversion ||
            tx.type == TransactionType.usdtToUsdcConversion ||
            tx.type == TransactionType.usdcToUsdtConversion;
      }
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
              decoration: BoxDecoration(
                color: asset.color,
                shape: BoxShape.circle,
              ),
              child: Icon(asset.icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${asset.name} (${asset.symbol})',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
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
          // Demo Banner vs Non-demo feature notice
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
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: featureState.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hub_outlined,
                        color: featureState.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${asset.symbol} • ${featureState.label}',
                          style: TextStyle(
                            color: featureState.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Backend provider integration pending. Real balances and on-chain transfers are not active yet.',
                          style: AppTypography.caption
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Total Stablecoin Balance Card
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
                color: asset.color.withValues(alpha: isDark ? 0.3 : 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'TOTAL ${asset.symbol} BALANCE',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: featureState.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        featureState.label,
                        style: TextStyle(
                          color: featureState.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  privacy.isBalanceHidden
                      ? '••••••'
                      : '\$${totalBalance.toStringAsFixed(2)}',
                  style: AppTypography.displaySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  privacy.isBalanceHidden
                      ? '•••• ${asset.symbol}'
                      : '${totalBalance.toStringAsFixed(2)} ${asset.symbol}',
                  style: TextStyle(
                    color: asset.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Available & Pending Breakdown
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            privacy.isBalanceHidden
                                ? '••••'
                                : '\$${availableBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            privacy.isBalanceHidden
                                ? '••••'
                                : '\$${pendingBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Secondary Network Metadata (kept non-dominant)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settlement',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Multi-rail',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Buttons: Send, Receive, Convert
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Send',
                  color: asset.color,
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
                  onTap: () => context.push('/receive'),
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

          // Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${asset.symbol} Activity',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (stablecoinTxs.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  'No recent ${asset.symbol} transactions',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            ...stablecoinTxs.take(5).map((tx) => _buildTxTile(context, tx, colors)),
        ],
      ),
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
            tx.destinationAmount != null
                ? '${tx.destinationAmount} ${tx.destinationAsset ?? ''}'
                : (tx.fiatAmount != null
                    ? '\$${tx.fiatAmount!.toStringAsFixed(2)}'
                    : '${tx.amountSats} sats'),
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
