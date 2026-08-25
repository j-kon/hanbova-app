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
  final bool coordinationSyncPending;
  final String? syncPendingStatus;

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
    this.coordinationSyncPending = false,
    this.syncPendingStatus,
  });

  bool get isOutgoing =>
      type == TransactionType.instantSend ||
      type == TransactionType.protectedSend;

  static const Object _sentinel = Object();

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    TransactionStatus? status,
    int? amountSats,
    String? recipientOrSender,
    String? description,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? claimReference,
    bool? coordinationSyncPending,
    Object? syncPendingStatus = _sentinel,
    bool clearSyncPendingStatus = false,
  }) {
    final effectiveSyncPendingStatus = clearSyncPendingStatus
        ? null
        : (identical(syncPendingStatus, _sentinel)
            ? this.syncPendingStatus
            : syncPendingStatus as String?);

    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      amountSats: amountSats ?? this.amountSats,
      recipientOrSender: recipientOrSender ?? this.recipientOrSender,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      claimReference: claimReference ?? this.claimReference,
      coordinationSyncPending:
          coordinationSyncPending ?? this.coordinationSyncPending,
      syncPendingStatus: effectiveSyncPendingStatus,
    );
  }
}
