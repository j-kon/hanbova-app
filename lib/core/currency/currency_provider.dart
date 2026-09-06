import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

abstract class ExchangeRateProvider {
  double getRate(FiatCurrency currency);
  bool get isLive;
}

/// Development exchange rate provider using calibrated African reference rates.
class DevelopmentExchangeRateProvider implements ExchangeRateProvider {
  const DevelopmentExchangeRateProvider();

  @override
  bool get isLive => false;

  @override
  double getRate(FiatCurrency currency) {
    switch (currency) {
      case FiatCurrency.ngn:
        return 95000000.0; // 1 BTC = 95M NGN
      case FiatCurrency.kes:
        return 7800000.0; // 1 BTC = 7.8M KES
      case FiatCurrency.ghs:
        return 900000.0; // 1 BTC = 900k GHS
      case FiatCurrency.zar:
        return 1100000.0; // 1 BTC = 1.1M ZAR
      case FiatCurrency.ugx:
        return 220000000.0; // 1 BTC = 220M UGX
      case FiatCurrency.rwf:
        return 80000000.0; // 1 BTC = 80M RWF
      case FiatCurrency.tzs:
        return 160000000.0; // 1 BTC = 160M TZS
      case FiatCurrency.usd:
        return 60000.0; // 1 BTC = $60k USD
      case FiatCurrency.eur:
        return 55000.0; // 1 BTC = €55k EUR
      case FiatCurrency.gbp:
        return 47000.0; // 1 BTC = £47k GBP
    }
  }
}

final exchangeRateProvider = Provider<ExchangeRateProvider>((ref) {
  return const DevelopmentExchangeRateProvider();
});

enum FiatCurrency {
  ngn('NGN', '₦'),
  usd('USD', r'$'),
  kes('KES', 'KSh '),
  ghs('GHS', 'GH₵ '),
  rwf('RWF', 'FRw '),
  ugx('UGX', 'USh '),
  tzs('TZS', 'TSh '),
  zar('ZAR', 'R '),
  eur('EUR', '€'),
  gbp('GBP', '£');

  final String code;
  final String symbol;

  const FiatCurrency(this.code, this.symbol);

  String get currencyName {
    switch (this) {
      case FiatCurrency.ngn:
        return 'Nigerian Naira';
      case FiatCurrency.usd:
        return 'US Dollar';
      case FiatCurrency.kes:
        return 'Kenyan Shilling';
      case FiatCurrency.ghs:
        return 'Ghanaian Cedi';
      case FiatCurrency.rwf:
        return 'Rwandan Franc';
      case FiatCurrency.ugx:
        return 'Ugandan Shilling';
      case FiatCurrency.tzs:
        return 'Tanzanian Shilling';
      case FiatCurrency.zar:
        return 'South African Rand';
      case FiatCurrency.eur:
        return 'Euro';
      case FiatCurrency.gbp:
        return 'British Pound';
    }
  }

  double satsToFiat(int sats,
      [ExchangeRateProvider rateProvider =
          const DevelopmentExchangeRateProvider()]) {
    final rate = rateProvider.getRate(this);
    return (sats / 100000000.0) * rate;
  }

  int fiatToSats(double fiatAmount,
      [ExchangeRateProvider rateProvider =
          const DevelopmentExchangeRateProvider()]) {
    if (fiatAmount <= 0) return 0;
    final rate = rateProvider.getRate(this);
    return ((fiatAmount / rate) * 100000000.0).round();
  }

  String format(int sats,
      [ExchangeRateProvider rateProvider =
          const DevelopmentExchangeRateProvider()]) {
    final amount = satsToFiat(sats, rateProvider);
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: code == 'UGX' || code == 'RWF' || code == 'TZS' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  String formatFiat(double amount) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: code == 'UGX' || code == 'RWF' || code == 'TZS' ? 0 : 2,
    );
    return formatter.format(amount);
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, FiatCurrency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<FiatCurrency> {
  static const _storageKey = 'hanbova_display_currency';
  final FlutterSecureStorage _storage;

  CurrencyNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(FiatCurrency.ngn) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final match = FiatCurrency.values.firstWhere(
          (c) => c.code == saved,
          orElse: () => FiatCurrency.ngn,
        );
        state = match;
      }
    } catch (_) {}
  }

  Future<void> setCurrency(FiatCurrency currency) async {
    state = currency;
    try {
      await _storage.write(key: _storageKey, value: currency.code);
    } catch (_) {}
  }
}
