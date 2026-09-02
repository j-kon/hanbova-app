import 'transaction_model.dart';

class ActivityExportService {
  /// Converts a list of transactions into an RFC-4180 compliant CSV string.
  static String exportToCsv(List<TransactionModel> transactions) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
        'Transaction ID,Date (UTC),Type,Counterparty,Amount (sats),Fiat Amount,Currency,Status,Description,Reference');

    for (final tx in transactions) {
      final id = _escapeCsv(tx.id);
      final date = tx.createdAt.toUtc().toIso8601String();
      final type = _escapeCsv(tx.displayTitle);
      final counterparty = _escapeCsv(tx.recipientOrSender);
      final amount = tx.amountSats.toString();
      final fiat = tx.fiatAmount?.toStringAsFixed(2) ?? '';
      final curr = tx.fiatCurrency ?? '';
      final status = tx.displayStatus.toUpperCase();
      final desc = _escapeCsv(tx.description ?? '');
      final ref = _escapeCsv(tx.receiptReference ?? tx.claimReference ?? '');

      buffer.writeln(
          '$id,$date,$type,$counterparty,$amount,$fiat,$curr,$status,$desc,$ref');
    }

    return buffer.toString();
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
