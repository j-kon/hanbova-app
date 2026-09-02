enum BillServiceType {
  airtime('Airtime', '📱', 'airtime'),
  data('Data Bundles', '🌐', 'data'),
  electricity('Electricity', '⚡', 'electricity'),
  water('Water', '💧', 'water'),
  tv('Pay TV', '📺', 'tv'),
  internet('Internet', '📶', 'internet');

  final String title;
  final String icon;
  final String key;

  const BillServiceType(this.title, this.icon, this.key);

  static BillServiceType fromKey(String key) {
    return BillServiceType.values.firstWhere(
      (v) => v.key == key.trim().toLowerCase(),
      orElse: () => BillServiceType.airtime,
    );
  }
}

class Biller {
  final String id;
  final String country;
  final BillServiceType serviceType;
  final String name;
  final String accountReferenceLabel;
  final String accountReferenceExample;
  final bool isActive;

  const Biller({
    required this.id,
    required this.country,
    required this.serviceType,
    required this.name,
    required this.accountReferenceLabel,
    required this.accountReferenceExample,
    this.isActive = true,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      id: json['id'] as String,
      country: json['country'] as String,
      serviceType: BillServiceType.fromKey(json['service_type'] as String? ?? 'airtime'),
      name: json['name'] as String,
      accountReferenceLabel: json['account_reference_label'] as String? ?? 'Account Reference',
      accountReferenceExample: json['account_reference_example'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class BillProduct {
  final String id;
  final String billerId;
  final String name;
  final String? description;
  final double amountFiat;
  final bool isVariableAmount;
  final double? minAmountFiat;
  final double? maxAmountFiat;

  const BillProduct({
    required this.id,
    required this.billerId,
    required this.name,
    this.description,
    required this.amountFiat,
    this.isVariableAmount = false,
    this.minAmountFiat,
    this.maxAmountFiat,
  });

  factory BillProduct.fromJson(Map<String, dynamic> json) {
    return BillProduct(
      id: json['id'] as String,
      billerId: json['biller_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amountFiat: (json['amount_fiat'] as num?)?.toDouble() ?? 0.0,
      isVariableAmount: json['is_variable_amount'] as bool? ?? false,
      minAmountFiat: (json['min_amount_fiat'] as num?)?.toDouble(),
      maxAmountFiat: (json['max_amount_fiat'] as num?)?.toDouble(),
    );
  }
}

class CustomerValidation {
  final bool isValid;
  final String billerId;
  final String customerAccount;
  final String? customerName;
  final double? outstandingAmountFiat;
  final String? message;

  const CustomerValidation({
    required this.isValid,
    required this.billerId,
    required this.customerAccount,
    this.customerName,
    this.outstandingAmountFiat,
    this.message,
  });

  factory CustomerValidation.fromJson(Map<String, dynamic> json) {
    return CustomerValidation(
      isValid: json['is_valid'] as bool? ?? false,
      billerId: json['biller_id'] as String? ?? '',
      customerAccount: json['customer_account'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      outstandingAmountFiat: (json['outstanding_amount_fiat'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }
}

class BillQuote {
  final String quoteId;
  final String billerId;
  final String? productId;
  final BillServiceType serviceType;
  final int amountSats;
  final double amountFiat;
  final int feeSats;
  final double exchangeRate;
  final String customerAccount;
  final DateTime expiresAt;

  const BillQuote({
    required this.quoteId,
    required this.billerId,
    this.productId,
    required this.serviceType,
    required this.amountSats,
    required this.amountFiat,
    required this.feeSats,
    required this.exchangeRate,
    required this.customerAccount,
    required this.expiresAt,
  });

  factory BillQuote.fromJson(Map<String, dynamic> json) {
    return BillQuote(
      quoteId: json['quote_id'] as String,
      billerId: json['biller_id'] as String,
      productId: json['product_id'] as String?,
      serviceType: BillServiceType.fromKey(json['service_type'] as String? ?? 'airtime'),
      amountSats: json['amount_sats'] as int? ?? 0,
      amountFiat: (json['amount_fiat'] as num?)?.toDouble() ?? 0.0,
      feeSats: json['fee_sats'] as int? ?? 0,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 0.0,
      customerAccount: json['customer_account'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 15)),
    );
  }
}

class BillTransaction {
  final String id;
  final String quoteId;
  final String billerId;
  final String billerName;
  final BillServiceType serviceType;
  final String customerAccount;
  final int amountSats;
  final double amountFiat;
  final int feeSats;
  final String status;
  final String? receiptNumber;
  final String? tokenCode;
  final String provider;
  final DateTime createdAt;

  const BillTransaction({
    required this.id,
    required this.quoteId,
    required this.billerId,
    required this.billerName,
    required this.serviceType,
    required this.customerAccount,
    required this.amountSats,
    required this.amountFiat,
    required this.feeSats,
    required this.status,
    this.receiptNumber,
    this.tokenCode,
    required this.provider,
    required this.createdAt,
  });

  factory BillTransaction.fromJson(Map<String, dynamic> json) {
    return BillTransaction(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String? ?? '',
      billerId: json['biller_id'] as String? ?? '',
      billerName: json['biller_name'] as String? ?? 'Biller',
      serviceType: BillServiceType.fromKey(json['service_type'] as String? ?? 'airtime'),
      customerAccount: json['customer_account'] as String? ?? '',
      amountSats: json['amount_sats'] as int? ?? 0,
      amountFiat: (json['amount_fiat'] as num?)?.toDouble() ?? 0.0,
      feeSats: json['fee_sats'] as int? ?? 0,
      status: json['status'] as String? ?? 'completed',
      receiptNumber: json['receipt_number'] as String?,
      tokenCode: json['token_code'] as String?,
      provider: json['provider'] as String? ?? 'dtone',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
