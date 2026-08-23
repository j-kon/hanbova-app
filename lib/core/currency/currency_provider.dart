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
        return 7800000.0;  // 1 BTC = 7.8M KES
      case FiatCurrency.ghs:
        return 900000.0;   // 1 BTC = 900k GHS
      case FiatCurrency.zar:
        return 1100000.0;  // 1 BTC = 1.1M ZAR
      case FiatCurrency.ugx:
        return 220000000.0;// 1 BTC = 220M UGX
      case FiatCurrency.rwf:
        return 80000000.0; // 1 BTC = 80M RWF
      case FiatCurrency.usd:
        return 60000.0;    // 1 BTC = $60k USD
    }
  }
}

final exchangeRateProvider = Provider<ExchangeRateProvider>((ref) {
  return const DevelopmentExchangeRateProvider();
});

enum FiatCurrency {
  ngn('NGN', '₦'),
  kes('KES', 'KSh '),
  ghs('GHS', 'GH₵ '),
  zar('ZAR', 'R '),
  ugx('UGX', 'USh '),
  rwf('RWF', 'FRw '),
  usd('USD', r'$');

  final String code;
  final String symbol;

  const FiatCurrency(this.code, this.symbol);

  double satsToFiat(int sats, [ExchangeRateProvider rateProvider = const DevelopmentExchangeRateProvider()]) {
    final rate = rateProvider.getRate(this);
    return (sats / 100000000.0) * rate;
  }

  int fiatToSats(double fiatAmount, [ExchangeRateProvider rateProvider = const DevelopmentExchangeRateProvider()]) {
    if (fiatAmount <= 0) return 0;
    final rate = rateProvider.getRate(this);
    return ((fiatAmount / rate) * 100000000.0).round();
  }

  String format(int sats, [ExchangeRateProvider rateProvider = const DevelopmentExchangeRateProvider()]) {
    final amount = satsToFiat(sats, rateProvider);
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: code == 'UGX' || code == 'RWF' ? 0 : 2,
    );
    return formatter.format(amount);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, FiatCurrency>((ref) {
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
