import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

enum FiatCurrency {
  ngn('NGN', '₦', 95000000.0), // 1 BTC = 95M NGN
  kes('KES', 'KSh ', 7800000.0), // 1 BTC = 7.8M KES
  ghs('GHS', 'GH₵ ', 900000.0),  // 1 BTC = 900k GHS
  zar('ZAR', 'R ', 1100000.0),   // 1 BTC = 1.1M ZAR
  ugx('UGX', 'USh ', 220000000.0),// 1 BTC = 220M UGX
  rwf('RWF', 'FRw ', 80000000.0), // 1 BTC = 80M RWF
  usd('USD', r'$', 60000.0);     // 1 BTC = $60k USD

  final String code;
  final String symbol;
  final double satsPerBtcRate; // Fiat value of 1 BTC (100M sats)

  const FiatCurrency(this.code, this.symbol, this.satsPerBtcRate);

  double satsToFiat(int sats) {
    return (sats / 100000000.0) * satsPerBtcRate;
  }

  int fiatToSats(double fiatAmount) {
    if (fiatAmount <= 0) return 0;
    return ((fiatAmount / satsPerBtcRate) * 100000000.0).round();
  }

  String format(int sats) {
    final amount = satsToFiat(sats);
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
