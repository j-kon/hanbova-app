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
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';

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

    final protectedCount = transactions.where((t) => t.type == TransactionType.protectedSend && t.status == TransactionStatus.claimable).length;
    final protectedSats = wallet.protectedOutgoingSats > 0 ? wallet.protectedOutgoingSats : 8500;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/me'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.primary.withValues(alpha: 0.15),
                            child: Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'J',
                              style: AppTypography.titleSmall.copyWith(color: colors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
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
                        isBalanceVisible ? Formatters.formatSats(totalBalanceSats) : '•••• sats',
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
                            child: _BalanceSubItem(
                              label: 'Spendable',
                              amount: isBalanceVisible ? Formatters.formatSats(wallet.spendableSats) : '••••',
                              color: colors.success,
                            ),
                          ),
                          Container(width: 1, height: 28, color: colors.divider),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.md),
                              child: _BalanceSubItem(
                                label: 'Protected',
                                amount: isBalanceVisible ? Formatters.formatSats(wallet.protectedOutgoingSats) : '••••',
                                color: colors.protected,
                              ),
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
                        onPressed: () => context.push('/receive'),
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

class _BalanceSubItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _BalanceSubItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(amount, style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontSize: 13)),
      ],
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
