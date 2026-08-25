import 'transaction_model.dart';

class ActivityExportService {
  /// Converts a list of transactions into an RFC-4180 compliant CSV string.
  static String exportToCsv(List<TransactionModel> transactions) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
        'Transaction ID,Date (UTC),Type,Counterparty,Amount (sats),Status,Description,Reference');

    for (final tx in transactions) {
      final id = _escapeCsv(tx.id);
      final date = tx.createdAt.toUtc().toIso8601String();
      final type = _formatType(tx.type);
      final counterparty = _escapeCsv(tx.recipientOrSender);
      final amount = tx.amountSats.toString();
      final status = tx.status.name.toUpperCase();
      final desc = _escapeCsv(tx.description ?? '');
      final ref = _escapeCsv(tx.claimReference ?? '');

      buffer
          .writeln('$id,$date,$type,$counterparty,$amount,$status,$desc,$ref');
    }

    return buffer.toString();
  }

  static String _formatType(TransactionType type) {
    switch (type) {
      case TransactionType.instantSend:
        return 'Instant Send (Lightning)';
      case TransactionType.instantReceive:
        return 'Instant Receive (Lightning)';
      case TransactionType.protectedSend:
        return 'Protected Send (Cashu P2PK)';
      case TransactionType.protectedClaim:
        return 'Protected Claim';
      case TransactionType.protectedRefund:
        return 'Protected Refund';
    }
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
