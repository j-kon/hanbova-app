enum TransactionType {
  instantSend,
  instantReceive,
  protectedSend,
  protectedClaim,
  protectedRefund,
}

enum TransactionStatus {
  pending,
  claimable,
  completed,
  expired,
  refunded,
  failed,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final int amountSats;
  final String recipientOrSender;
  final String? description;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? claimReference;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amountSats,
    required this.recipientOrSender,
    this.description,
    required this.createdAt,
    this.expiresAt,
    this.claimReference,
  });

  bool get isOutgoing =>
      type == TransactionType.instantSend ||
      type == TransactionType.protectedSend;
}
