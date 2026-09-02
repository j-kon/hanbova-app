import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/transactions/domain/activity_export_service.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';

void main() {
  group('ActivityExportService Tests', () {
    test('exportToCsv generates valid RFC-4180 CSV with header and records',
        () {
      final txList = [
        TransactionModel(
          id: 'tx_001',
          recipientOrSender: 'Amara (@amara)',
          amountSats: 25000,
          type: TransactionType.bitcoinSent,
          status: TransactionStatus.completed,
          createdAt: DateTime.utc(2026, 8, 23, 12, 0, 0),
          description: 'Payment for groceries',
        ),
        TransactionModel(
          id: 'tx_002',
          recipientOrSender: 'Kwame (@kwame)',
          amountSats: 50000,
          type: TransactionType.protectedPayment,
          status: TransactionStatus.waitingForRecipient,
          createdAt: DateTime.utc(2026, 8, 23, 14, 30, 0),
          description: 'Payment for Laptop, Lagos delivery',
          claimReference: 'claim_ref_123',
        ),
      ];

      final csv = ActivityExportService.exportToCsv(txList);
      final lines = csv.trim().split('\n');

      expect(lines.length, 3);
      expect(lines[0],
          'Transaction ID,Date (UTC),Type,Counterparty,Amount (sats),Fiat Amount,Currency,Status,Description,Reference');
      expect(lines[1], contains('tx_001'));
      expect(lines[1], contains('Bitcoin Sent'));
      expect(lines[1], contains('25000'));
      expect(lines[2], contains('tx_002'));
      expect(lines[2], contains('Protected Payment'));
      expect(lines[2], contains('"Payment for Laptop, Lagos delivery"'));
      expect(lines[2], contains('claim_ref_123'));
    });
  });
}
