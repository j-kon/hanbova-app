enum TransactionType {
  bitcoinReceived,
  bitcoinSent,
  instantReceive,
  instantSend,
  protectedPayment,
  protectedSend,
  protectedClaim,
  protectedRefund,
  airtime,
  data,
  electricity,
  water,
  tv,
  internet,
  esimPurchase,
  esimTopup,
  bankPayout,
  mobileMoneyPayout,
  cardFunding,
  cardPayment,
  cardRefund,
  // Stablecoins
  usdtSent,
  usdtReceived,
  usdcSent,
  usdcReceived,
  // Conversions
  btcToUsdtConversion,
  btcToUsdcConversion,
  usdtToBtcConversion,
  usdcToBtcConversion,
  usdtToUsdcConversion,
  usdcToUsdtConversion,
}

enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  claimable,
  expired,
  uncertain,
  // Protected-specific statuses
  waitingForRecipient,
  claimed,
  refundAvailable,
  refunding,
}

enum TransactionCategory {
  moneyIn,
  moneyOut,
  protected,
  bills,
  travel,
  cards,
  conversions,
  stablecoins,
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

  // Rich consumer details
  final double? fiatAmount;
  final String? fiatCurrency;
  final int? feeSats;
  final String? billerName;
  final String? accountReference;
  final String? tokenOrPin;
  final String? paymentMethod;
  final String? spendCountry;
  final String? receiptReference;
  final String? planName;
  final Map<String, dynamic>? metadata;

  // Conversion & Stablecoin specific fields
  final String? sourceAsset;
  final double? sourceAmount;
  final String? destinationAsset;
  final double? destinationAmount;
  final double? exchangeRate;
  final String? hanbovaReference;

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
    this.fiatAmount,
    this.fiatCurrency,
    this.feeSats,
    this.billerName,
    this.accountReference,
    this.tokenOrPin,
    this.paymentMethod,
    this.spendCountry,
    this.receiptReference,
    this.planName,
    this.metadata,
    this.sourceAsset,
    this.sourceAmount,
    this.destinationAsset,
    this.destinationAmount,
    this.exchangeRate,
    this.hanbovaReference,
  });

  bool get isOutgoing {
    switch (type) {
      case TransactionType.bitcoinSent:
      case TransactionType.instantSend:
      case TransactionType.protectedPayment:
      case TransactionType.protectedSend:
      case TransactionType.airtime:
      case TransactionType.data:
      case TransactionType.electricity:
      case TransactionType.water:
      case TransactionType.tv:
      case TransactionType.internet:
      case TransactionType.esimPurchase:
      case TransactionType.esimTopup:
      case TransactionType.bankPayout:
      case TransactionType.mobileMoneyPayout:
      case TransactionType.cardFunding:
      case TransactionType.cardPayment:
      case TransactionType.usdtSent:
      case TransactionType.usdcSent:
        return true;
      case TransactionType.bitcoinReceived:
      case TransactionType.instantReceive:
      case TransactionType.protectedClaim:
      case TransactionType.protectedRefund:
      case TransactionType.cardRefund:
      case TransactionType.usdtReceived:
      case TransactionType.usdcReceived:
      case TransactionType.btcToUsdtConversion:
      case TransactionType.btcToUsdcConversion:
      case TransactionType.usdtToBtcConversion:
      case TransactionType.usdcToBtcConversion:
      case TransactionType.usdtToUsdcConversion:
      case TransactionType.usdcToUsdtConversion:
        return false;
    }
  }

  bool get isConversion =>
      type == TransactionType.btcToUsdtConversion ||
      type == TransactionType.btcToUsdcConversion ||
      type == TransactionType.usdtToBtcConversion ||
      type == TransactionType.usdcToBtcConversion ||
      type == TransactionType.usdtToUsdcConversion ||
      type == TransactionType.usdcToUsdtConversion;

  bool get isStablecoin =>
      type == TransactionType.usdtSent ||
      type == TransactionType.usdtReceived ||
      type == TransactionType.usdcSent ||
      type == TransactionType.usdcReceived;

  TransactionCategory get category {
    switch (type) {
      case TransactionType.bitcoinReceived:
      case TransactionType.instantReceive:
      case TransactionType.protectedClaim:
      case TransactionType.protectedRefund:
      case TransactionType.cardRefund:
        return TransactionCategory.moneyIn;
      case TransactionType.bitcoinSent:
      case TransactionType.instantSend:
      case TransactionType.bankPayout:
      case TransactionType.mobileMoneyPayout:
        return TransactionCategory.moneyOut;
      case TransactionType.protectedPayment:
      case TransactionType.protectedSend:
        return TransactionCategory.protected;
      case TransactionType.airtime:
      case TransactionType.data:
      case TransactionType.electricity:
      case TransactionType.water:
      case TransactionType.tv:
      case TransactionType.internet:
        return TransactionCategory.bills;
      case TransactionType.esimPurchase:
      case TransactionType.esimTopup:
        return TransactionCategory.travel;
      case TransactionType.cardFunding:
      case TransactionType.cardPayment:
        return TransactionCategory.cards;
      case TransactionType.usdtSent:
      case TransactionType.usdcSent:
      case TransactionType.usdtReceived:
      case TransactionType.usdcReceived:
        return TransactionCategory.stablecoins;
      case TransactionType.btcToUsdtConversion:
      case TransactionType.btcToUsdcConversion:
      case TransactionType.usdtToBtcConversion:
      case TransactionType.usdcToBtcConversion:
      case TransactionType.usdtToUsdcConversion:
      case TransactionType.usdcToUsdtConversion:
        return TransactionCategory.conversions;
    }
  }

  String get displayTitle {
    switch (type) {
      case TransactionType.bitcoinReceived:
      case TransactionType.instantReceive:
        return 'Bitcoin Received';
      case TransactionType.bitcoinSent:
      case TransactionType.instantSend:
        return 'Bitcoin Sent';
      case TransactionType.protectedPayment:
      case TransactionType.protectedSend:
        return 'Protected Payment';
      case TransactionType.protectedClaim:
        return 'Protected Claim';
      case TransactionType.protectedRefund:
        return 'Protected Refund';
      case TransactionType.airtime:
        return billerName ?? 'Airtime Top-up';
      case TransactionType.data:
        return billerName ?? 'Mobile Data Bundle';
      case TransactionType.electricity:
        return billerName ?? 'Electricity Token';
      case TransactionType.water:
        return billerName ?? 'Water Utility';
      case TransactionType.tv:
        return billerName ?? 'Pay TV Subscription';
      case TransactionType.internet:
        return billerName ?? 'Fixed Internet';
      case TransactionType.esimPurchase:
        return planName ?? 'eSIM Data Plan';
      case TransactionType.esimTopup:
        return planName ?? 'eSIM Top-up';
      case TransactionType.bankPayout:
        return 'Bank Transfer';
      case TransactionType.mobileMoneyPayout:
        return 'Mobile Money Payout';
      case TransactionType.cardFunding:
        return 'Card Funding';
      case TransactionType.cardPayment:
        return 'Card Payment';
      case TransactionType.cardRefund:
        return 'Card Refund';
      case TransactionType.usdtSent:
        return 'USDT Sent';
      case TransactionType.usdtReceived:
        return 'USDT Received';
      case TransactionType.usdcSent:
        return 'USDC Sent';
      case TransactionType.usdcReceived:
        return 'USDC Received';
      case TransactionType.btcToUsdtConversion:
        return 'BTC → USDT Conversion';
      case TransactionType.btcToUsdcConversion:
        return 'BTC → USDC Conversion';
      case TransactionType.usdtToBtcConversion:
        return 'USDT → BTC Conversion';
      case TransactionType.usdcToBtcConversion:
        return 'USDC → BTC Conversion';
      case TransactionType.usdtToUsdcConversion:
        return 'USDT → USDC Conversion';
      case TransactionType.usdcToUsdtConversion:
        return 'USDC → USDT Conversion';
    }
  }

  String get displayStatus {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
      case TransactionStatus.claimable:
      case TransactionStatus.waitingForRecipient:
        return 'Waiting for recipient';
      case TransactionStatus.claimed:
        return 'Claimed';
      case TransactionStatus.expired:
      case TransactionStatus.refundAvailable:
        return 'Refund available';
      case TransactionStatus.refunding:
        return 'Refunding';
      case TransactionStatus.uncertain:
        return 'Status Uncertain';
    }
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'amountSats': amountSats,
        'recipientOrSender': recipientOrSender,
        'description': description,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'claimReference': claimReference,
        'coordinationSyncPending': coordinationSyncPending,
        'syncPendingStatus': syncPendingStatus,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, Object? raw, String field) {
      if (raw is! String) {
        throw FormatException('Invalid transaction $field.');
      }
      return values.firstWhere(
        (value) => value.name == raw,
        orElse: () => throw FormatException('Invalid transaction $field.'),
      );
    }

    String requiredString(String field) {
      final value = json[field];
      if (value is! String || value.isEmpty) {
        throw FormatException('Invalid transaction $field.');
      }
      return value;
    }

    DateTime requiredDate(String field) {
      final raw = requiredString(field);
      return DateTime.tryParse(raw)?.toUtc() ??
          (throw FormatException('Invalid transaction $field.'));
    }

    DateTime? optionalDate(String field) {
      final raw = json[field];
      if (raw == null) return null;
      if (raw is! String) {
        throw FormatException('Invalid transaction $field.');
      }
      return DateTime.tryParse(raw)?.toUtc() ??
          (throw FormatException('Invalid transaction $field.'));
    }

    String? optionalString(String field) {
      final value = json[field];
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('Invalid transaction $field.');
      }
      return value;
    }

    final amountSats = json['amountSats'];
    final coordinationSyncPending = json['coordinationSyncPending'] ?? false;
    if (amountSats is! int ||
        amountSats < 0 ||
        coordinationSyncPending is! bool) {
      throw const FormatException('Invalid transaction values.');
    }

    return TransactionModel(
      id: requiredString('id'),
      type: enumValue(TransactionType.values, json['type'], 'type'),
      status: enumValue(TransactionStatus.values, json['status'], 'status'),
      amountSats: amountSats,
      recipientOrSender: requiredString('recipientOrSender'),
      description: optionalString('description'),
      createdAt: requiredDate('createdAt'),
      expiresAt: optionalDate('expiresAt'),
      claimReference: optionalString('claimReference'),
      coordinationSyncPending: coordinationSyncPending,
      syncPendingStatus: optionalString('syncPendingStatus'),
    );
  }

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
    double? fiatAmount,
    String? fiatCurrency,
    int? feeSats,
    String? billerName,
    String? accountReference,
    String? tokenOrPin,
    String? paymentMethod,
    String? spendCountry,
    String? receiptReference,
    String? planName,
    Map<String, dynamic>? metadata,
    String? sourceAsset,
    double? sourceAmount,
    String? destinationAsset,
    double? destinationAmount,
    double? exchangeRate,
    String? hanbovaReference,
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
      fiatAmount: fiatAmount ?? this.fiatAmount,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      feeSats: feeSats ?? this.feeSats,
      billerName: billerName ?? this.billerName,
      accountReference: accountReference ?? this.accountReference,
      tokenOrPin: tokenOrPin ?? this.tokenOrPin,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      spendCountry: spendCountry ?? this.spendCountry,
      receiptReference: receiptReference ?? this.receiptReference,
      planName: planName ?? this.planName,
      metadata: metadata ?? this.metadata,
      sourceAsset: sourceAsset ?? this.sourceAsset,
      sourceAmount: sourceAmount ?? this.sourceAmount,
      destinationAsset: destinationAsset ?? this.destinationAsset,
      destinationAmount: destinationAmount ?? this.destinationAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      hanbovaReference: hanbovaReference ?? this.hanbovaReference,
    );
  }
}
