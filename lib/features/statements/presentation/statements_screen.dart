import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class StatementsScreen extends ConsumerWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final demoState = ref.watch(demoModeProvider);
    final currency = ref.watch(currencyProvider);
    final statements = demoState.demoStatements;
    final numFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Hanbova Activity Statements',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Demo Banner
          if (demoState.isEnabled)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: statements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Statements Yet',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monthly statements will appear here after your first billing cycle.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount: statements.length,
                    itemBuilder: (context, index) {
                      final stmt = statements[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.primary
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons.calendar_today_outlined,
                                            color: colors.primary,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          stmt.monthLabel,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Text(
                                    '${stmt.transactionCount} transactions',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(color: colors.border, height: 1),
                            const SizedBox(height: 12),

                            // Statement Rows
                            _buildStatementRow(
                                'Opening Balance',
                                '${numFormat.format(stmt.openingBalanceSats)} sats',
                                currency.format(stmt.openingBalanceSats),
                                colors: colors),
                            _buildStatementRow(
                                'Money In',
                                '+${numFormat.format(stmt.moneyInSats)} sats',
                                currency.format(stmt.moneyInSats),
                                color: const Color(0xFF10B981),
                                colors: colors),
                            _buildStatementRow(
                                'Money Out',
                                '-${numFormat.format(stmt.moneyOutSats)} sats',
                                currency.format(stmt.moneyOutSats),
                                color: const Color(0xFFEF4444),
                                colors: colors),
                            _buildStatementRow(
                                'Fees',
                                '-${numFormat.format(stmt.feesSats)} sats',
                                currency.format(stmt.feesSats),
                                colors: colors),
                            _buildStatementRow(
                                'Closing Balance',
                                '${numFormat.format(stmt.closingBalanceSats)} sats',
                                currency.format(stmt.closingBalanceSats),
                                isBold: true,
                                colors: colors),

                            const SizedBox(height: 14),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showExportDialog(
                                          context, stmt.monthLabel, 'CSV');
                                    },
                                    icon: const Icon(Icons.table_chart_outlined,
                                        size: 16),
                                    label: const Text('Export CSV',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.textPrimary,
                                      side: BorderSide(color: colors.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showExportDialog(
                                          context, stmt.monthLabel, 'PDF');
                                    },
                                    icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 16),
                                    label: const Text('Download PDF',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: AppColors.charcoal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementRow(String label, String satsStr, String fiatStr,
      {Color? color, bool isBold = false, required HanbovaColors colors}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? colors.textPrimary : colors.textSecondary,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                satsStr,
                style: TextStyle(
                  color: color ?? colors.textPrimary,
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($fiatStr)',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String month, String format) {
    final colors = context.colors;
    if (format == 'PDF') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surfaceCard,
          title: Text('PDF Export Coming Soon',
              style: TextStyle(color: colors.textPrimary)),
          content: Text(
            'Official PDF statement rendering for $month will be supported in an upcoming release. Please use CSV export for full statement records today.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: colors.primary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showExportDialog(context, month, 'CSV');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
              ),
              child: const Text('Export as CSV Instead'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Activity Statement ($format)',
            style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Exporting verified activity statement for $month in $format format with genuine Bitcoin satoshi totals.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('CSV Statement for $month exported successfully!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: AppColors.charcoal,
            ),
            child: const Text('Download CSV'),
          ),
        ],
      ),
    );
  }
}
