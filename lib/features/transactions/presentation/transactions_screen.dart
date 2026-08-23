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
import '../domain/activity_export_service.dart';
import '../domain/transaction_model.dart';
import 'transactions_provider.dart';

enum ActivityFilter { all, sent, received, protected }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  ActivityFilter _selectedFilter = ActivityFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportActivity(List<TransactionModel> transactions) {
    final csv = ActivityExportService.exportToCsv(transactions);

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          title: const Text('Export Activity (CSV)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transactions.length} transactions prepared for export in standard RFC-4180 CSV format.',
                style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: colors.border),
                ),
                height: 120,
                child: SingleChildScrollView(
                  child: Text(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy CSV'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allTransactions = ref.watch(transactionsProvider);

    final filtered = allTransactions.where((tx) {
      // 1. Filter by category
      bool matchesCategory = true;
      switch (_selectedFilter) {
        case ActivityFilter.all:
          matchesCategory = true;
          break;
        case ActivityFilter.sent:
          matchesCategory = tx.type == TransactionType.instantSend || tx.type == TransactionType.protectedSend;
          break;
        case ActivityFilter.received:
          matchesCategory = tx.type == TransactionType.instantReceive || tx.type == TransactionType.protectedClaim;
          break;
        case ActivityFilter.protected:
          matchesCategory = tx.type == TransactionType.protectedSend ||
              tx.type == TransactionType.protectedClaim ||
              tx.type == TransactionType.protectedRefund;
          break;
      }

      if (!matchesCategory) return false;

      // 2. Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchRecipient = tx.recipientOrSender.toLowerCase().contains(q);
        final matchDesc = (tx.description ?? '').toLowerCase().contains(q);
        final matchId = tx.id.toLowerCase().contains(q);
        final matchRef = (tx.claimReference ?? '').toLowerCase().contains(q);
        return matchRecipient || matchDesc || matchId || matchRef;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Activity'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: 'Search Activity',
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
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: () => _exportActivity(filtered),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by handle, memo, or ID...',
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

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedFilter == ActivityFilter.all,
                      onTap: () => setState(() => _selectedFilter = ActivityFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: 'Sent',
                      isSelected: _selectedFilter == ActivityFilter.sent,
                      onTap: () => setState(() => _selectedFilter = ActivityFilter.sent),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: 'Received',
                      isSelected: _selectedFilter == ActivityFilter.received,
                      onTap: () => setState(() => _selectedFilter = ActivityFilter.received),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      label: 'Protected',
                      isSelected: _selectedFilter == ActivityFilter.protected,
                      onTap: () => setState(() => _selectedFilter = ActivityFilter.protected),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Transactions list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, color: colors.textTertiary, size: 48),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _searchQuery.isNotEmpty ? 'No matches found' : 'No transactions found',
                            style: AppTypography.titleSmall.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for a different handle or keyword.'
                                : 'Payments matching this filter will show here.',
                            style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return _ActivityItemTile(tx: tx);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
            color: isSelected ? const Color(0xFF003822) : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ActivityItemTile extends ConsumerWidget {
  final TransactionModel tx;

  const _ActivityItemTile({required this.tx});

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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientOrSender,
                      style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          Formatters.formatDate(tx.createdAt),
                          style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 11),
                        ),
                        if (tx.type == TransactionType.protectedSend) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.protected.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PROTECTED',
                              style: AppTypography.labelSmall.copyWith(color: colors.protected, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
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
