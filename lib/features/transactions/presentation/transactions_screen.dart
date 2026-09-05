import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/security/privacy_provider.dart';
import '../../../core/sync/wallet_sync_coordinator.dart';
import 'activity_transaction_tile.dart';
import '../domain/activity_export_service.dart';
import '../domain/transaction_model.dart';
import 'transaction_details_screen.dart';
import 'transactions_provider.dart';

enum QuickFilter {
  all,
  bitcoin,
  conversions,
  stablecoins,
  moneyIn,
  moneyOut,
  protected,
  bills,
  travel,
  cards,
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  QuickFilter _selectedQuickFilter = QuickFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Advanced Filters State
  TransactionStatus? _filterStatus;
  String? _filterCountry;
  DateTimeRange? _filterDateRange;
  RangeValues? _filterAmountRange;

  bool _refreshFailed = false;

  Future<void> _fetchTransactions() async {
    try {
      await ref.read(walletSyncCoordinatorProvider)?.syncNow();
      if (mounted) setState(() => _refreshFailed = false);
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    return all.where((tx) {
      // 1. Quick Filter
      switch (_selectedQuickFilter) {
        case QuickFilter.all:
          break;
        case QuickFilter.bitcoin:
          if (tx.isConversion || tx.isStablecoin) return false;
          break;
        case QuickFilter.conversions:
          if (!tx.isConversion) return false;
          break;
        case QuickFilter.stablecoins:
          if (!tx.isStablecoin) return false;
          break;
        case QuickFilter.moneyIn:
          if (tx.category != TransactionCategory.moneyIn) return false;
          break;
        case QuickFilter.moneyOut:
          if (tx.category != TransactionCategory.moneyOut) return false;
          break;
        case QuickFilter.protected:
          if (tx.category != TransactionCategory.protected) return false;
          break;
        case QuickFilter.bills:
          if (tx.category != TransactionCategory.bills) return false;
          break;
        case QuickFilter.travel:
          if (tx.category != TransactionCategory.travel) return false;
          break;
        case QuickFilter.cards:
          if (tx.category != TransactionCategory.cards) return false;
          break;
      }

      // 2. Search query (human-friendly references)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchRecipient =
            tx.recipientOrSender.toLowerCase().contains(query);
        final matchBiller =
            tx.billerName?.toLowerCase().contains(query) ?? false;
        final matchPlan = tx.planName?.toLowerCase().contains(query) ?? false;
        final matchRef =
            tx.receiptReference?.toLowerCase().contains(query) ?? false;
        final matchAccount =
            tx.accountReference?.toLowerCase().contains(query) ?? false;
        final matchDesc =
            tx.description?.toLowerCase().contains(query) ?? false;

        if (!matchRecipient &&
            !matchBiller &&
            !matchPlan &&
            !matchRef &&
            !matchAccount &&
            !matchDesc) {
          return false;
        }
      }

      // 3. Advanced filters
      if (_filterStatus != null && tx.status != _filterStatus) {
        return false;
      }

      if (_filterCountry != null &&
          tx.spendCountry?.toUpperCase() != _filterCountry?.toUpperCase()) {
        return false;
      }

      if (_filterDateRange != null) {
        if (tx.createdAt.isBefore(_filterDateRange!.start) ||
            tx.createdAt
                .isAfter(_filterDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      if (_filterAmountRange != null) {
        if (tx.amountSats < _filterAmountRange!.start ||
            tx.amountSats > _filterAmountRange!.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openAdvancedFiltersModal() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterStatus = null;
                            _filterCountry = null;
                            _filterDateRange = null;
                            _filterAmountRange = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text('Reset All',
                            style: TextStyle(color: colors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Status',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChoiceChip(
                        label: 'All Statuses',
                        selected: _filterStatus == null,
                        onSelected: (sel) {
                          setModalState(() => _filterStatus = null);
                          setState(() => _filterStatus = null);
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Completed',
                        selected: _filterStatus == TransactionStatus.completed,
                        onSelected: (sel) {
                          setModalState(() => _filterStatus =
                              sel ? TransactionStatus.completed : null);
                          setState(() => _filterStatus =
                              sel ? TransactionStatus.completed : null);
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Waiting for Recipient',
                        selected: _filterStatus ==
                                TransactionStatus.waitingForRecipient ||
                            _filterStatus == TransactionStatus.claimable,
                        onSelected: (sel) {
                          setModalState(() => _filterStatus = sel
                              ? TransactionStatus.waitingForRecipient
                              : null);
                          setState(() => _filterStatus = sel
                              ? TransactionStatus.waitingForRecipient
                              : null);
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Refund Available',
                        selected: _filterStatus ==
                                TransactionStatus.refundAvailable ||
                            _filterStatus == TransactionStatus.expired,
                        onSelected: (sel) {
                          setModalState(() => _filterStatus =
                              sel ? TransactionStatus.refundAvailable : null);
                          setState(() => _filterStatus =
                              sel ? TransactionStatus.refundAvailable : null);
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Refunded',
                        selected: _filterStatus == TransactionStatus.refunded,
                        onSelected: (sel) {
                          setModalState(() => _filterStatus =
                              sel ? TransactionStatus.refunded : null);
                          setState(() => _filterStatus =
                              sel ? TransactionStatus.refunded : null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Destination / Spend Country',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChoiceChip(
                        label: 'Any Country',
                        selected: _filterCountry == null,
                        onSelected: (sel) {
                          setModalState(() => _filterCountry = null);
                          setState(() => _filterCountry = null);
                        },
                      ),
                      for (final c in ['KE', 'NG', 'GH', 'ZA', 'UG', 'RW'])
                        _buildFilterChoiceChip(
                          label: c,
                          selected: _filterCountry == c,
                          onSelected: (sel) {
                            setModalState(
                                () => _filterCountry = sel ? c : null);
                            setState(() => _filterCountry = sel ? c : null);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colors = context.colors;
    final isDark = context.isDark;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : colors.textPrimary,
              fontSize: 12)),
      selected: selected,
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(color: selected ? colors.primary : colors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: onSelected,
    );
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
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textSecondary),
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
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allTransactions = ref.watch(transactionsProvider);
    final transactions = _applyFilters(allTransactions);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search recipient, biller, reference...',
                  hintStyle:
                      TextStyle(color: colors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Text(
                'Activity',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            tooltip: _isSearchVisible ? 'Close search' : 'Search activity',
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search,
                color: colors.textPrimary),
            onPressed: () {
              setState(() {
                if (_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: (_filterStatus != null ||
                      _filterCountry != null ||
                      _filterDateRange != null ||
                      _filterAmountRange != null)
                  ? colors.primary
                  : colors.textSecondary,
            ),
            tooltip: 'Advanced Filters',
            onPressed: _openAdvancedFiltersModal,
          ),
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: colors.primary),
            tooltip: 'Export CSV',
            onPressed: () => _exportActivity(transactions),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_refreshFailed || allTransactions.isStale)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Icon(Icons.cloud_off_outlined, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Showing saved activity. Refresh to check the latest status.',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary))),
                TextButton(
                    onPressed: _fetchTransactions, child: const Text('Retry')),
              ]),
            ),
          if (allTransactions.isSyncing)
            const LinearProgressIndicator(minHeight: 2),
          // Quick Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildQuickFilterChip('All', QuickFilter.all),
                _buildQuickFilterChip('Bitcoin', QuickFilter.bitcoin),
                _buildQuickFilterChip('Conversions', QuickFilter.conversions),
                _buildQuickFilterChip('Stablecoins', QuickFilter.stablecoins),
                _buildQuickFilterChip('Money In', QuickFilter.moneyIn),
                _buildQuickFilterChip('Money Out', QuickFilter.moneyOut),
                _buildQuickFilterChip('Protected', QuickFilter.protected),
                _buildQuickFilterChip('Bills', QuickFilter.bills),
                _buildQuickFilterChip('Travel', QuickFilter.travel),
                _buildQuickFilterChip('Cards', QuickFilter.cards),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTransactions,
              color: colors.primary,
              child: transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _buildTransactionItem(context, tx);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, QuickFilter filter) {
    final colors = context.colors;
    final isSelected = _selectedQuickFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.charcoal : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: colors.primary,
        backgroundColor: colors.surfaceCard,
        side: BorderSide(color: isSelected ? colors.primary : colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) setState(() => _selectedQuickFilter = filter);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    final filtered = _searchQuery.isNotEmpty ||
        _selectedQuickFilter != QuickFilter.all ||
        _filterStatus != null ||
        _filterCountry != null ||
        _filterDateRange != null ||
        _filterAmountRange != null;
    return LayoutBuilder(
        builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  filtered
                                      ? Icons.search_off
                                      : Icons.receipt_long_outlined,
                                  color: colors.textSecondary,
                                  size: 48),
                              const SizedBox(height: 16),
                              Text(
                                  filtered
                                      ? 'No matching payments'
                                      : 'Your activity starts here',
                                  style: AppTypography.titleMedium
                                      .copyWith(color: colors.textPrimary),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(
                                  filtered
                                      ? 'Try another search or clear your filters.'
                                      : 'Payments will appear here with their latest status. Pull down to refresh.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: colors.textSecondary)),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                  onPressed: filtered
                                      ? () => setState(() {
                                            _selectedQuickFilter =
                                                QuickFilter.all;
                                            _searchQuery = '';
                                            _searchController.clear();
                                            _filterStatus = null;
                                            _filterCountry = null;
                                            _filterDateRange = null;
                                            _filterAmountRange = null;
                                          })
                                      : _fetchTransactions,
                                  icon: Icon(filtered
                                      ? Icons.filter_alt_off_outlined
                                      : Icons.refresh),
                                  label: Text(filtered
                                      ? 'Clear filters'
                                      : 'Refresh activity')),
                            ]))),
              ],
            ));
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    return ActivityTransactionTile(
      transaction: tx,
      currency: ref.watch(currencyProvider),
      hideAmounts: ref.watch(privacyProvider).isBalanceHidden,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TransactionDetailsScreen(transaction: tx))),
    );
  }
}
