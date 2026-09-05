import 'package:intl/intl.dart';

/// The customer-facing settlement/conversion rate offered through Hanbova's
/// configured provider.
class HanbovaRate {
  final String market;
  final String base;
  final String quote;
  final String display;
  final String settlementAsset;
  final double rate;
  final String provider;
  final bool isLive;
  final bool isStale;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  const HanbovaRate({
    required this.market,
    required this.base,
    required this.quote,
    required this.display,
    required this.settlementAsset,
    required this.rate,
    required this.provider,
    required this.isLive,
    required this.isStale,
    required this.updatedAt,
    this.expiresAt,
  });

  factory HanbovaRate.fromJson(Map<String, dynamic> json) {
    final market = json['market'] as String? ?? 'NG';
    final base = json['base'] as String? ?? 'USD';
    final quote = json['quote'] as String? ?? 'NGN';
    final settlementAsset = json['settlement_asset'] as String? ?? 'USDT';
    final rate = (json['rate'] as num?)?.toDouble() ?? 0.0;
    final provider = json['provider'] as String? ?? 'bitnob';
    final isLive = json['is_live'] as bool? ?? false;
    final isStale = json['is_stale'] as bool? ?? false;
    final updatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
        : DateTime.now();
    final expiresAt = json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'] as String)
        : null;

    final display = json['display'] as String? ??
        formatDisplay(base: base, quote: quote, rate: rate);

    return HanbovaRate(
      market: market,
      base: base,
      quote: quote,
      display: display,
      settlementAsset: settlementAsset,
      rate: rate,
      provider: provider,
      isLive: isLive,
      isStale: isStale,
      updatedAt: updatedAt,
      expiresAt: expiresAt,
    );
  }

  /// Factory for a deterministic demo / mock rate.
  ///
  /// NOTE: Demo rates are NEVER marked isLive = true.
  factory HanbovaRate.demo({
    String market = 'NG',
    String base = 'USD',
    String quote = 'NGN',
    String settlementAsset = 'USDT',
    double rate = 1365.00,
    bool isStale = false,
    DateTime? updatedAt,
  }) {
    return HanbovaRate(
      market: market,
      base: base,
      quote: quote,
      display: formatDisplay(base: base, quote: quote, rate: rate),
      settlementAsset: settlementAsset,
      rate: rate,
      provider: 'bitnob',
      isLive: false, // Explicitly not live
      isStale: isStale,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static String formatDisplay({
    required String base,
    required String quote,
    required double rate,
  }) {
    final baseSymbol = base == 'USD'
        ? r'$1'
        : base == 'EUR'
            ? '€1'
            : base == 'GBP'
                ? '£1'
                : base;

    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedRate = formatter.format(rate);

    final quoteSymbol = quote == 'NGN'
        ? '₦'
        : quote == 'KES'
            ? 'KSh '
            : quote == 'GHS'
                ? 'GH₵ '
                : quote == 'ZAR'
                    ? 'R '
                    : '$quote ';

    return '$baseSymbol = $quoteSymbol$formattedRate';
  }

  HanbovaRate copyWith({
    String? market,
    String? base,
    String? quote,
    String? display,
    String? settlementAsset,
    double? rate,
    String? provider,
    bool? isLive,
    bool? isStale,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return HanbovaRate(
      market: market ?? this.market,
      base: base ?? this.base,
      quote: quote ?? this.quote,
      display: display ?? this.display,
      settlementAsset: settlementAsset ?? this.settlementAsset,
      rate: rate ?? this.rate,
      provider: provider ?? this.provider,
      isLive: isLive ?? this.isLive,
      isStale: isStale ?? this.isStale,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Status of the platform rate for UI rendering.
enum HanbovaRateStatus {
  live,
  stale,
  loading,
  unavailable,
  demo,
}

/// State object representing the rate in the application.
class HanbovaRateState {
  final HanbovaRateStatus status;
  final HanbovaRate? rate;
  final String? errorMessage;
  final DateTime? lastChecked;

  const HanbovaRateState({
    required this.status,
    this.rate,
    this.errorMessage,
    this.lastChecked,
  });

  const HanbovaRateState.initial()
      : status = HanbovaRateStatus.loading,
        rate = null,
        errorMessage = null,
        lastChecked = null;

  bool get isLive => status == HanbovaRateStatus.live;
  bool get isStale => status == HanbovaRateStatus.stale;
  bool get isLoading => status == HanbovaRateStatus.loading;
  bool get isUnavailable => status == HanbovaRateStatus.unavailable;
  bool get isDemo => status == HanbovaRateStatus.demo;

  HanbovaRateState copyWith({
    HanbovaRateStatus? status,
    HanbovaRate? rate,
    String? errorMessage,
    DateTime? lastChecked,
  }) {
    return HanbovaRateState(
      status: status ?? this.status,
      rate: rate ?? this.rate,
      errorMessage: errorMessage ?? this.errorMessage,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}
