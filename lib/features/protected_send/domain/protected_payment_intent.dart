class ProtectedPaymentIntent {
  final String id;
  final String paymentType;
  final String status;
  final int amountSats;
  final String? senderId;
  final String recipientIdentifier;
  final String? description;
  final DateTime? expiresAt;
  final String? claimReference;
  final DateTime createdAt;

  const ProtectedPaymentIntent({
    required this.id,
    required this.paymentType,
    required this.status,
    required this.amountSats,
    this.senderId,
    required this.recipientIdentifier,
    this.description,
    this.expiresAt,
    this.claimReference,
    required this.createdAt,
  });

  factory ProtectedPaymentIntent.fromJson(Map<String, dynamic> json) {
    return ProtectedPaymentIntent(
      id: json['id'] as String,
      paymentType: json['payment_type'] as String,
      status: json['status'] as String,
      amountSats: json['amount_sats'] is int
          ? json['amount_sats'] as int
          : int.parse(json['amount_sats'].toString()),
      senderId: json['sender_id'] as String?,
      recipientIdentifier: json['recipient_identifier'] as String,
      description: json['description'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      claimReference: json['claim_reference'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_type': paymentType,
      'status': status,
      'amount_sats': amountSats,
      'sender_id': senderId,
      'recipient_identifier': recipientIdentifier,
      'description': description,
      'expires_at': expiresAt?.toIso8601String(),
      'claim_reference': claimReference,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
