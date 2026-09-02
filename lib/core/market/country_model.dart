import 'package:hanbova_app/core/currency/currency_provider.dart';

/// Static reference metadata for supported countries.
class CountryInfo {
  final String code; // 2-letter ISO (e.g. "KE")
  final String name;
  final String flagEmoji;
  final FiatCurrency defaultCurrency;
  final String dialCode;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.defaultCurrency,
    required this.dialCode,
  });

  static const List<CountryInfo> supportedCountries = [
    CountryInfo(
      code: 'KE',
      name: 'Kenya',
      flagEmoji: '🇰🇪',
      defaultCurrency: FiatCurrency.kes,
      dialCode: '+254',
    ),
    CountryInfo(
      code: 'NG',
      name: 'Nigeria',
      flagEmoji: '🇳🇬',
      defaultCurrency: FiatCurrency.ngn,
      dialCode: '+234',
    ),
    CountryInfo(
      code: 'GH',
      name: 'Ghana',
      flagEmoji: '🇬🇭',
      defaultCurrency: FiatCurrency.ghs,
      dialCode: '+233',
    ),
    CountryInfo(
      code: 'ZA',
      name: 'South Africa',
      flagEmoji: '🇿🇦',
      defaultCurrency: FiatCurrency.zar,
      dialCode: '+27',
    ),
    CountryInfo(
      code: 'UG',
      name: 'Uganda',
      flagEmoji: '🇺🇬',
      defaultCurrency: FiatCurrency.ugx,
      dialCode: '+256',
    ),
    CountryInfo(
      code: 'RW',
      name: 'Rwanda',
      flagEmoji: '🇷🇼',
      defaultCurrency: FiatCurrency.rwf,
      dialCode: '+250',
    ),
  ];

  static CountryInfo findByCode(String code) {
    final upper = code.trim().toUpperCase();
    return supportedCountries.firstWhere(
      (c) => c.code == upper,
      orElse: () => const CountryInfo(
        code: 'KE',
        name: 'Kenya',
        flagEmoji: '🇰🇪',
        defaultCurrency: FiatCurrency.kes,
        dialCode: '+254',
      ),
    );
  }
}

/// Normalized market capability matrix.
class MarketCapabilities {
  final bool payouts;
  final bool mobileMoney;
  final bool cards;
  final bool airtime;
  final bool data;
  final bool electricity;
  final bool water;
  final bool tv;
  final bool internet;
  final bool esim;

  const MarketCapabilities({
    this.payouts = false,
    this.mobileMoney = false,
    this.cards = false,
    this.airtime = false,
    this.data = false,
    this.electricity = false,
    this.water = false,
    this.tv = false,
    this.internet = false,
    this.esim = false,
  });

  factory MarketCapabilities.fromJson(Map<String, dynamic> json) {
    return MarketCapabilities(
      payouts: json['payouts'] as bool? ?? false,
      mobileMoney: json['mobile_money'] as bool? ?? false,
      cards: json['cards'] as bool? ?? false,
      airtime: json['airtime'] as bool? ?? false,
      data: json['data'] as bool? ?? false,
      electricity: json['electricity'] as bool? ?? false,
      water: json['water'] as bool? ?? false,
      tv: json['tv'] as bool? ?? false,
      internet: json['internet'] as bool? ?? false,
      esim: json['esim'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'payouts': payouts,
        'mobile_money': mobileMoney,
        'cards': cards,
        'airtime': airtime,
        'data': data,
        'electricity': electricity,
        'water': water,
        'tv': tv,
        'internet': internet,
        'esim': esim,
      };
}

/// Tri-part user country context separating identity, active spending market, and UI currency.
class UserCountryContext {
  /// The user's real onboarding / KYC / residency origin (e.g. "NG").
  final String identityCountry;

  /// The market where the user currently wants to spend or travel (e.g. "KE").
  final String spendCountry;

  /// The active currency shown in UI (e.g. "KES").
  final FiatCurrency displayCurrency;

  /// Active capabilities of the selected spend market.
  final MarketCapabilities capabilities;

  const UserCountryContext({
    required this.identityCountry,
    required this.spendCountry,
    required this.displayCurrency,
    this.capabilities = const MarketCapabilities(
      payouts: true,
      mobileMoney: true,
      cards: true,
      airtime: true,
      data: true,
      electricity: true,
      water: true,
      tv: true,
      internet: true,
      esim: true,
    ),
  });

  CountryInfo get identityCountryInfo => CountryInfo.findByCode(identityCountry);
  CountryInfo get spendCountryInfo => CountryInfo.findByCode(spendCountry);

  UserCountryContext copyWith({
    String? identityCountry,
    String? spendCountry,
    FiatCurrency? displayCurrency,
    MarketCapabilities? capabilities,
  }) {
    return UserCountryContext(
      identityCountry: identityCountry ?? this.identityCountry,
      spendCountry: spendCountry ?? this.spendCountry,
      displayCurrency: displayCurrency ?? this.displayCurrency,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}
