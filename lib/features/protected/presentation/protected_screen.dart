import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';

enum ProtectedFilter {
  active,
  incoming,
  completed,
}

class ProtectedScreen extends ConsumerStatefulWidget {
  const ProtectedScreen({super.key});

  @override
  ConsumerState<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends ConsumerState<ProtectedScreen> {
  ProtectedFilter _selectedFilter = ProtectedFilter.active;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allTransactions = ref.watch(transactionsProvider);

    final activeOutgoing = allTransactions
        .where((t) => t.type == TransactionType.protectedSend && t.status == TransactionStatus.claimable)
        .toList();

    final incoming = allTransactions
        .where((t) => t.type == TransactionType.protectedClaim && t.status == TransactionStatus.claimable)
        .toList();

    final completed = allTransactions
        .where((t) =>
            (t.type == TransactionType.protectedSend ||
                t.type == TransactionType.protectedClaim ||
                t.type == TransactionType.protectedRefund) &&
            (t.status == TransactionStatus.completed || t.status == TransactionStatus.refunded))
        .toList();

    List<TransactionModel> currentList;
    switch (_selectedFilter) {
      case ProtectedFilter.active:
        currentList = activeOutgoing;
        break;
      case ProtectedFilter.incoming:
        currentList = incoming;
        break;
      case ProtectedFilter.completed:
        currentList = completed;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      currentList = currentList.where((t) {
        return t.recipientOrSender.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            t.id.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Protected'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: 'Search protected payments',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Protected Send',
            onPressed: () => context.push('/protected-send'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Optional Search Bar
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by handle, claim code, or memo...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

            // Modern Pill Filter Chips (matching Activity screen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Active (${activeOutgoing.length})',
                      isSelected: _selectedFilter == ProtectedFilter.active,
                      onTap: () => setState(() => _selectedFilter = ProtectedFilter.active),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: 'Incoming (${incoming.length})',
                      isSelected: _selectedFilter == ProtectedFilter.incoming,
                      onTap: () => setState(() => _selectedFilter = ProtectedFilter.incoming),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: 'Completed (${completed.length})',
                      isSelected: _selectedFilter == ProtectedFilter.completed,
                      onTap: () => setState(() => _selectedFilter = ProtectedFilter.completed),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Tab Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildCurrentTab(currentList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(List<TransactionModel> items) {
    switch (_selectedFilter) {
      case ProtectedFilter.active:
        return _ActiveTab(key: const ValueKey('active_tab'), items: items);
      case ProtectedFilter.incoming:
        return _IncomingTab(key: const ValueKey('incoming_tab'), items: items);
      case ProtectedFilter.completed:
        return _CompletedTab(key: const ValueKey('completed_tab'), items: items);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceElevated,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.deepForest
                    : Colors.white)
                : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ActiveTab extends ConsumerWidget {
  final List<TransactionModel> items;

  const _ActiveTab({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colors.protected.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: colors.protected, size: 36),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No active protected payments',
                style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Send money with timelocked recipient claiming and self-service refund protection.',
                style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.push('/protected-send'),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Send Protected'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final tx = items[index];
        final now = DateTime.now();
        final isExpired = tx.expiresAt != null && now.isAfter(tx.expiresAt!);
        final timeLeft = tx.expiresAt != null && !isExpired
            ? tx.expiresAt!.difference(now)
            : Duration.zero;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isExpired ? colors.primary.withValues(alpha: 0.5) : colors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.protected.withValues(alpha: 0.12),
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: Icon(Icons.shield_outlined, color: colors.protected, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.recipientOrSender,
                                style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                                maxLines: 1,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.formatSats(tx.amountSats),
                        style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
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
              const SizedBox(height: AppSpacing.md),

              if (tx.claimReference != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Claim code: ',
                        style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11),
                      ),
                      Expanded(
                        child: Text(
                          tx.claimReference!,
                          style: AppTypography.bodySmall.copyWith(color: colors.primary, fontFamily: 'monospace', fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: tx.claimReference!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim code copied!')));
                        },
                        child: Icon(Icons.copy, size: 15, color: colors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Locktime Status & Action
              if (isExpired) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: colors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Locktime expired • Refund available',
                            style: AppTypography.labelSmall.copyWith(color: colors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Payment was not claimed. Tap Refund to return funds to your spendable balance.',
                        style: AppTypography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    ref.read(walletStateProvider.notifier).unlockRefundToSpendable(tx.amountSats);
                    ref.read(transactionsProvider.notifier).updateTransactionStatus(tx.id, TransactionStatus.refunded);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refunded ${Formatters.formatSats(tx.amountSats)} to spendable balance')),
                    );
                  },
                  child: const Text('Refund available'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: colors.warning, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Refund available in ${_formatDuration(timeLeft)}',
                        style: AppTypography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }
}

class _IncomingTab extends ConsumerWidget {
  final List<TransactionModel> items;

  const _IncomingTab({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inbox_outlined, color: colors.primary, size: 36),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No incoming protected payments',
                style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'When someone sends you a protected payment, you can claim it here.',
                style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => context.push('/claim'),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Enter claim code'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final tx = items[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.incoming.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(Icons.check_circle_outline, color: colors.incoming, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientOrSender,
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatSats(tx.amountSats),
                      style: AppTypography.bodyMedium.copyWith(color: colors.success, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ElevatedButton(
                onPressed: () {
                  ref.read(walletStateProvider.notifier).creditBalance(tx.amountSats);
                  ref.read(transactionsProvider.notifier).updateTransactionStatus(tx.id, TransactionStatus.completed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Claimed ${Formatters.formatSats(tx.amountSats)} successfully!')),
                  );
                },
                child: const Text('Claim'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletedTab extends ConsumerWidget {
  final List<TransactionModel> items;

  const _CompletedTab({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, color: colors.textTertiary, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No completed protected payments yet',
                style: AppTypography.titleSmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Claimed and refunded protected payments will show here.',
                style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final tx = items[index];
        final isRefunded = tx.status == TransactionStatus.refunded;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isRefunded ? colors.primary : colors.success).withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(
                  isRefunded ? Icons.replay : Icons.check_circle_outline,
                  color: isRefunded ? colors.primary : colors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientOrSender,
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatDate(tx.createdAt)} • ${isRefunded ? "REFUNDED" : "CLAIMED"}',
                      style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                Formatters.formatSats(tx.amountSats),
                style: AppTypography.titleSmall.copyWith(
                  color: isRefunded ? colors.primary : colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
