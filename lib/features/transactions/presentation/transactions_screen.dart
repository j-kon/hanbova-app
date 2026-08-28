import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../protected_send/data/payment_intent_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;
    try {
      final intentRepo = ref.read(paymentIntentRepositoryProvider);
      final intents = await intentRepo.getPaymentIntents();
      if (!mounted) return;
      await ref.read(transactionsProvider.notifier).syncPaymentIntents(
            intents: intents,
            currentUserId: authState.user!.id,
            currentUsername: authState.user!.username,
          );
    } catch (_) {}
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
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13)),
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
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13)),
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
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
    final isDark = context.isDark;
    final isSelected = _selectedQuickFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : colors.textPrimary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                color: colors.textTertiary, size: 54),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedQuickFilter != QuickFilter.all
                  ? 'Try adjusting your search or filters.'
                  : 'Your Bitcoin payments, protected sends, utility bills, and travel activity will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (tx.type) {
      case TransactionType.bitcoinReceived:
      case TransactionType.instantReceive:
      case TransactionType.protectedClaim:
      case TransactionType.cardRefund:
        icon = Icons.arrow_downward;
        iconColor = AppColors.success;
        iconBg = AppColors.success.withValues(alpha: 0.15);
        break;
      case TransactionType.bitcoinSent:
      case TransactionType.instantSend:
      case TransactionType.bankPayout:
      case TransactionType.mobileMoneyPayout:
        icon = Icons.arrow_upward;
        iconColor = AppColors.danger;
        iconBg = AppColors.danger.withValues(alpha: 0.15);
        break;
      case TransactionType.protectedPayment:
      case TransactionType.protectedSend:
        icon = Icons.shield_outlined;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withValues(alpha: 0.15);
        break;
      case TransactionType.protectedRefund:
        icon = Icons.replay;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withValues(alpha: 0.15);
        break;
      case TransactionType.airtime:
        icon = Icons.phone_android;
        iconColor = Colors.lightBlueAccent;
        iconBg = Colors.lightBlueAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.data:
        icon = Icons.wifi;
        iconColor = Colors.cyanAccent;
        iconBg = Colors.cyanAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.electricity:
        icon = Icons.bolt;
        iconColor = Colors.amberAccent;
        iconBg = Colors.amberAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.water:
        icon = Icons.water_drop;
        iconColor = Colors.tealAccent;
        iconBg = Colors.tealAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.tv:
        icon = Icons.tv;
        iconColor = Colors.purpleAccent;
        iconBg = Colors.purpleAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.internet:
        icon = Icons.router;
        iconColor = Colors.orangeAccent;
        iconBg = Colors.orangeAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.esimPurchase:
      case TransactionType.esimTopup:
        icon = Icons.sim_card_outlined;
        iconColor = Colors.pinkAccent;
        iconBg = Colors.pinkAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.cardFunding:
      case TransactionType.cardPayment:
        icon = Icons.credit_card;
        iconColor = Colors.indigoAccent;
        iconBg = Colors.indigoAccent.withValues(alpha: 0.15);
        break;
      case TransactionType.usdtSent:
      case TransactionType.usdtReceived:
        icon = Icons.attach_money_rounded;
        iconColor = const Color(0xFF26A17B);
        iconBg = const Color(0xFF26A17B).withValues(alpha: 0.15);
        break;
      case TransactionType.usdcSent:
      case TransactionType.usdcReceived:
        icon = Icons.monetization_on_rounded;
        iconColor = const Color(0xFF2775CA);
        iconBg = const Color(0xFF2775CA).withValues(alpha: 0.15);
        break;
      case TransactionType.btcToUsdtConversion:
      case TransactionType.btcToUsdcConversion:
      case TransactionType.usdtToBtcConversion:
      case TransactionType.usdcToBtcConversion:
      case TransactionType.usdtToUsdcConversion:
      case TransactionType.usdcToUsdtConversion:
        icon = Icons.swap_horiz_rounded;
        iconColor = const Color(0xFF38BDF8);
        iconBg = const Color(0xFF38BDF8).withValues(alpha: 0.15);
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailsScreen(transaction: tx),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.recipientOrSender} • ${Formatters.formatDate(tx.createdAt)}',
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isOutgoing ? '-' : '+'}${Formatters.formatSats(tx.amountSats)}',
                  style: TextStyle(
                    color: tx.isOutgoing ? colors.textPrimary : colors.incoming,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currency.format(tx.amountSats),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
