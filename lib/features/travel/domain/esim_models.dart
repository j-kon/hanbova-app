class EsimPackage {
  final String id;
  final String country;
  final String region;
  final String name;
  final int dataAllowanceMb;
  final int validityDays;
  final int priceSats;
  final double priceFiat;
  final String currency;
  final String carrier;
  final String networkSpeed;
  final bool topUpSupported;

  const EsimPackage({
    required this.id,
    required this.country,
    required this.region,
    required this.name,
    required this.dataAllowanceMb,
    required this.validityDays,
    required this.priceSats,
    required this.priceFiat,
    required this.currency,
    required this.carrier,
    required this.networkSpeed,
    this.topUpSupported = true,
  });

  String get formattedData {
    if (dataAllowanceMb >= 1024) {
      return '${(dataAllowanceMb / 1024).toStringAsFixed(0)} GB';
    }
    return '$dataAllowanceMb MB';
  }

  factory EsimPackage.fromJson(Map<String, dynamic> json) {
    return EsimPackage(
      id: json['id'] as String,
      country: json['country'] as String,
      region: json['region'] as String? ?? 'Africa',
      name: json['name'] as String,
      dataAllowanceMb: json['data_allowance_mb'] as int? ?? 1024,
      validityDays: json['validity_days'] as int? ?? 7,
      priceSats: json['price_sats'] as int? ?? 5000,
      priceFiat: (json['price_fiat'] as num?)?.toDouble() ?? 3.50,
      currency: json['currency'] as String? ?? 'USD',
      carrier: json['carrier'] as String? ?? 'Multi-Carrier',
      networkSpeed: json['network_speed'] as String? ?? '4G/5G',
      topUpSupported: json['top_up_supported'] as bool? ?? true,
    );
  }
}

class EsimProfile {
  final String id;
  final String packageId;
  final String packageName;
  final String country;
  final String iccid;
  final String matchingId;
  final String smdpAddress;
  final String qrCodeData;
  final String iosInstallationUrl;
  final String androidInstallationUrl;
  final int dataAllowanceMb;
  final int remainingDataMb;
  final String status;
  final bool topUpSupported;
  final DateTime createdAt;
  final DateTime expiresAt;

  const EsimProfile({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.country,
    required this.iccid,
    required this.matchingId,
    required this.smdpAddress,
    required this.qrCodeData,
    required this.iosInstallationUrl,
    required this.androidInstallationUrl,
    required this.dataAllowanceMb,
    required this.remainingDataMb,
    required this.status,
    this.topUpSupported = true,
    required this.createdAt,
    required this.expiresAt,
  });

  double get dataRemainingFraction {
    if (dataAllowanceMb <= 0) return 0.0;
    return (remainingDataMb / dataAllowanceMb).clamp(0.0, 1.0);
  }

  String get formattedRemaining {
    if (remainingDataMb >= 1024) {
      return '${(remainingDataMb / 1024.0).toStringAsFixed(1)} GB';
    }
    return '$remainingDataMb MB';
  }

  factory EsimProfile.fromJson(Map<String, dynamic> json) {
    return EsimProfile(
      id: json['id'] as String,
      packageId: json['package_id'] as String? ?? '',
      packageName: json['package_name'] as String? ?? 'eSIM Plan',
      country: json['country'] as String? ?? 'KE',
      iccid: json['iccid'] as String? ?? '892340000000',
      matchingId: json['matching_id'] as String? ?? '',
      smdpAddress: json['smdp_address'] as String? ?? 'rsp.dtone.com',
      qrCodeData: json['qr_code_data'] as String? ?? '',
      iosInstallationUrl: json['ios_installation_url'] as String? ?? '',
      androidInstallationUrl: json['android_installation_url'] as String? ?? '',
      dataAllowanceMb: json['data_allowance_mb'] as int? ?? 1024,
      remainingDataMb: json['remaining_data_mb'] as int? ?? 1024,
      status: json['status'] as String? ?? 'active',
      topUpSupported: json['top_up_supported'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 15)),
    );
  }
}

class PayoutCorridor {
  final String id;
  final String country;
  final String currency;
  final String channel;
  final String name;
  final double minAmountFiat;
  final double maxAmountFiat;
  final int estimatedFeeSats;

  const PayoutCorridor({
    required this.id,
    required this.country,
    required this.currency,
    required this.channel,
    required this.name,
    required this.minAmountFiat,
    required this.maxAmountFiat,
    required this.estimatedFeeSats,
  });

  bool get isMobileMoney =>
      channel.toLowerCase().contains('mobile') ||
      channel.toLowerCase().contains('momo') ||
      channel.toLowerCase().contains('mpesa');

  String get type => channel;

  factory PayoutCorridor.fromJson(Map<String, dynamic> json) {
    return PayoutCorridor(
      id: json['id'] as String,
      country: json['country'] as String,
      currency: json['currency'] as String,
      channel: json['channel'] as String,
      name: json['name'] as String,
      minAmountFiat: (json['min_amount_fiat'] as num?)?.toDouble() ?? 100.0,
      maxAmountFiat: (json['max_amount_fiat'] as num?)?.toDouble() ?? 100000.0,
      estimatedFeeSats: json['estimated_fee_sats'] as int? ?? 250,
    );
  }
}

class CardEligibilityInfo {
  final bool isEligible;
  final String country;
  final List<String> supportedTypes;
  final int minFundingSats;
  final String? reason;

  const CardEligibilityInfo({
    required this.isEligible,
    required this.country,
    required this.supportedTypes,
    required this.minFundingSats,
    this.reason,
  });

  factory CardEligibilityInfo.fromJson(Map<String, dynamic> json) {
    return CardEligibilityInfo(
      isEligible: json['is_eligible'] as bool? ?? false,
      country: json['country'] as String? ?? 'KE',
      supportedTypes: (json['supported_types'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      minFundingSats: json['min_funding_sats'] as int? ?? 5000,
      reason: json['reason'] as String?,
    );
  }
}
