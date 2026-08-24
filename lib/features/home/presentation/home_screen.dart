import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/balance_visibility_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../security/presentation/mainnet_safety_dialog.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../../../core/network/network_environment.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final wallet = ref.watch(walletStateProvider);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final currency = ref.watch(currencyProvider);
    final transactions = ref.watch(transactionsProvider);

    final totalBalanceSats = wallet.totalSats;
    final greeting = _getGreeting();
    final firstName = user?.firstName.isNotEmpty == true ? user!.firstName : 'Jeremiah';

    final currentNetwork = ref.watch(networkEnvironmentProvider);
    final isMainnet = currentNetwork == HanbovaNetwork.mainnet;

    final protectedCount = transactions.where((t) => t.type == TransactionType.protectedSend && t.status == TransactionStatus.claimable).length;
    final protectedSats = transactions
        .where((t) => t.type == TransactionType.protectedSend && t.status == TransactionStatus.claimable)
        .fold<int>(0, (sum, t) => sum + t.amountSats);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletStateProvider);
            ref.invalidate(transactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (User profile, Greeting, Actions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'H',
                            style: AppTypography.titleMedium.copyWith(color: colors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppTypography.caption.copyWith(color: colors.textSecondary),
                            ),
                            Text(
                              firstName,
                              style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded, color: colors.textPrimary),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Balance Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: colors.border, width: 1),
                    boxShadow: AppShadows.card(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (!isMainnet) {
                            MainnetSafetyDialog.show(context);
                          }
                        },
                        borderRadius: AppRadius.xsRadius,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isMainnet ? colors.success : Colors.amber).withValues(alpha: 0.12),
                            borderRadius: AppRadius.xsRadius,
                            border: Border.all(
                              color: (isMainnet ? colors.success : Colors.amber).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMainnet ? Icons.verified_user : Icons.science_outlined,
                                color: isMainnet ? colors.success : Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isMainnet ? 'MAINNET BETA • Real Bitcoin' : 'TEST MODE • No monetary value',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isMainnet ? colors.success : Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                          IconButton(
                            icon: Icon(
                              isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: colors.textTertiary,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref.read(balanceVisibilityProvider.notifier).toggle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Fiat display
                      Text(
                        isBalanceVisible ? currency.format(totalBalanceSats) : '••••••••',
                        style: AppTypography.display.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Sats display
                      Text(
                        isBalanceVisible
                            ? '${Formatters.formatSatsNumber(totalBalanceSats)} ${isMainnet ? "sats" : "test sats"}'
                            : '•••• ${isMainnet ? "sats" : "test sats"}',
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Divider & Breakdown
                      Divider(color: colors.divider),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spendable',
                                  style: AppTypography.caption.copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBalanceVisible
                                      ? Formatters.formatSats(wallet.spendableSats)
                                      : '••••',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 28, width: 1, color: colors.divider),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protected Escrow',
                                  style: AppTypography.caption.copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBalanceVisible
                                      ? Formatters.formatSats(wallet.protectedOutgoingSats)
                                      : '••••',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: colors.protected,
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
                const SizedBox(height: AppSpacing.md),

                // 3. Primary Action Buttons (Send / Receive)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/send'),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: const Color(0xFF003822),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => UnifiedDepositSheet.show(context),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: const Text('Receive'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Protected Summary Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.protected.withValues(alpha: 0.08),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: colors.protected.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.protected.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_outlined, color: colors.protected, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protected Payments',
                              style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$protectedCount active • ${Formatters.formatSats(protectedSats)} protected',
                              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/protected'),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 5. Quick Claim Banner
                Material(
                  color: colors.surfaceCard,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    onTap: () => context.push('/claim'),
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, color: colors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Have a claim code?',
                              style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
                            ),
                          ),
                          Text(
                            'Claim',
                            style: AppTypography.titleSmall.copyWith(color: colors.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: colors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 6. Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
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
                          Icon(Icons.receipt_long_outlined, color: colors.textTertiary, size: 36),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No transactions yet',
                            style: AppTypography.titleSmall.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your Hanbova payments will appear here.',
                            style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...transactions.take(4).map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _TransactionCard(tx: tx),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final TransactionModel tx;

  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    IconData icon;
    Color iconColor;
    String prefix;

    switch (tx.type) {
      case TransactionType.instantSend:
        icon = Icons.arrow_upward;
        iconColor = colors.outgoing;
        prefix = '-';
        break;
      case TransactionType.instantReceive:
        icon = Icons.arrow_downward;
        iconColor = colors.incoming;
        prefix = '+';
        break;
      case TransactionType.protectedSend:
        icon = Icons.shield_outlined;
        iconColor = colors.protected;
        prefix = '-';
        break;
      case TransactionType.protectedClaim:
        icon = Icons.check_circle_outline;
        iconColor = colors.incoming;
        prefix = '+';
        break;
      case TransactionType.protectedRefund:
        icon = Icons.replay;
        iconColor = colors.success;
        prefix = '+';
        break;
    }

    return Material(
      color: colors.surfaceCard,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: () => context.push('/activity/details', extra: tx),
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientOrSender,
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatDate(tx.createdAt),
                      style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix${Formatters.formatSats(tx.amountSats)}',
                    style: AppTypography.titleSmall.copyWith(
                      color: tx.isOutgoing ? colors.textPrimary : colors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(tx.amountSats),
                    style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
