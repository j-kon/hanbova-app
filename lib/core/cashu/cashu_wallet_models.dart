/// Represents a single Cashu Proof belonging to the client wallet.
class CashuProof {
  final int amount;
  final String secret;
  final String c;
  final String id;
  final String? witness;

  const CashuProof({
    required this.amount,
    required this.secret,
    required this.c,
    required this.id,
    this.witness,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'secret': secret,
        'C': c,
        'id': id,
        if (witness != null) 'witness': witness,
      };

  factory CashuProof.fromJson(Map<String, dynamic> json) => CashuProof(
        amount: json['amount'] as int,
        secret: json['secret'] as String,
        c: json['C'] as String,
        id: json['id'] as String,
        witness: json['witness'] as String?,
      );
}

/// Status of an ecash token at the Cashu mint.
enum TokenState {
  unspent,
  spent,
  pending,
  unknown,
}

/// Balance breakdown of the client-side Cashu wallet.
class CashuWalletBalance {
  final int spendableSats;
  final int lockedEscrowSats;

  const CashuWalletBalance({
    required this.spendableSats,
    required this.lockedEscrowSats,
  });

  int get totalSats => spendableSats + lockedEscrowSats;
}

/// Client-persisted record of a Protected Escrow created or received by this device.
class ProtectedEscrowRecord {
  final String paymentId;
  final String token;
  final int amountSats;
  final String recipientPubkey;
  final String? refundPubkey;
  final String? refundPrivkeyHex; // Retained strictly client-side by sender for post-locktime refund
  final DateTime locktime;
  final bool isOutgoing;
  final String status; // 'locked', 'claimed', 'refunded', 'expired'
  final DateTime createdAt;

  const ProtectedEscrowRecord({
    required this.paymentId,
    required this.token,
    required this.amountSats,
    required this.recipientPubkey,
    this.refundPubkey,
    this.refundPrivkeyHex,
    required this.locktime,
    required this.isOutgoing,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'token': token,
        'amountSats': amountSats,
        'recipientPubkey': recipientPubkey,
        'refundPubkey': refundPubkey,
        'refundPrivkeyHex': refundPrivkeyHex,
        'locktime': locktime.toIso8601String(),
        'isOutgoing': isOutgoing,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProtectedEscrowRecord.fromJson(Map<String, dynamic> json) =>
      ProtectedEscrowRecord(
        paymentId: json['paymentId'] as String,
        token: json['token'] as String,
        amountSats: json['amountSats'] as int,
        recipientPubkey: json['recipientPubkey'] as String,
        refundPubkey: json['refundPubkey'] as String?,
        refundPrivkeyHex: json['refundPrivkeyHex'] as String?,
        locktime: DateTime.parse(json['locktime'] as String),
        isOutgoing: json['isOutgoing'] as bool,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  ProtectedEscrowRecord copyWith({
    String? status,
  }) =>
      ProtectedEscrowRecord(
        paymentId: paymentId,
        token: token,
        amountSats: amountSats,
        recipientPubkey: recipientPubkey,
        refundPubkey: refundPubkey,
        refundPrivkeyHex: refundPrivkeyHex,
        locktime: locktime,
        isOutgoing: isOutgoing,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

/// Result of requesting a melt quote (NUT-05) for paying a Lightning invoice from ecash.
class MeltQuoteResult {
  final String quoteId;
  final int amountSats;
  final int feeReserveSats;

  const MeltQuoteResult({
    required this.quoteId,
    required this.amountSats,
    required this.feeReserveSats,
  });

  int get totalRequiredSats => amountSats + feeReserveSats;
}

/// Result of executing a melt operation (NUT-05).
class MeltExecutionResult {
  final bool isPaid;
  final String? preimage;

  const MeltExecutionResult({
    required this.isPaid,
    this.preimage,
  });
}

