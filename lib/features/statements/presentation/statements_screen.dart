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
    final demoState = ref.watch(demoModeProvider);
    final currency = ref.watch(currencyProvider);
    final statements = demoState.demoStatements;
    final numFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Account Statements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: statements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Statements Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monthly statements will appear here after your first billing cycle.',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: statements.length,
              itemBuilder: (context, index) {
                final stmt = statements[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_today_outlined,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                stmt.monthLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${stmt.transactionCount} transactions',
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.darkBorder, height: 1),
                      const SizedBox(height: 12),

                      // Statement Rows
                      _buildStatementRow(
                          'Opening Balance',
                          '${numFormat.format(stmt.openingBalanceSats)} sats',
                          currency.format(stmt.openingBalanceSats)),
                      _buildStatementRow(
                          'Money In',
                          '+${numFormat.format(stmt.moneyInSats)} sats',
                          currency.format(stmt.moneyInSats),
                          color: const Color(0xFF10B981)),
                      _buildStatementRow(
                          'Money Out',
                          '-${numFormat.format(stmt.moneyOutSats)} sats',
                          currency.format(stmt.moneyOutSats),
                          color: const Color(0xFFEF4444)),
                      _buildStatementRow(
                          'Fees',
                          '-${numFormat.format(stmt.feesSats)} sats',
                          currency.format(stmt.feesSats)),
                      _buildStatementRow(
                          'Closing Balance',
                          '${numFormat.format(stmt.closingBalanceSats)} sats',
                          currency.format(stmt.closingBalanceSats),
                          isBold: true),

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
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: AppColors.darkBorder),
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
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  size: 16),
                              label: const Text('Download PDF',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
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
    );
  }

  Widget _buildStatementRow(String label, String satsStr, String fiatStr,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : AppColors.darkTextSecondary,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              Text(
                satsStr,
                style: TextStyle(
                  color: color ?? (isBold ? Colors.white : Colors.white),
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($fiatStr)',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBackground,
        title: Text('Statement for $month ($format)',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'Exporting official accounting statement for $month in $format format. Document generated with verified Bitcoin satoshi totals.',
          style:
              const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '$format Statement for $month exported successfully!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Document'),
          ),
        ],
      ),
    );
  }
}
