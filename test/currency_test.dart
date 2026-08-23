import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';

void main() {
  group('Display Currency Tests', () {
    test('Converts satoshis to NGN, KES, GHS, ZAR, USD accurately', () {
      const sats = 100000; // 0.001 BTC

      // 1 BTC = 95,000,000 NGN -> 0.001 BTC = 95,000 NGN
      expect(FiatCurrency.ngn.satsToFiat(sats), 95000.0);
      expect(FiatCurrency.ngn.format(sats), '₦95,000.00');

      // 1 BTC = 7,800,000 KES -> 0.001 BTC = 7,800 KES
      expect(FiatCurrency.kes.satsToFiat(sats), 7800.0);
      expect(FiatCurrency.kes.format(sats), 'KSh 7,800.00');

      // 1 BTC = 900,000 GHS -> 0.001 BTC = 900 GHS
      expect(FiatCurrency.ghs.satsToFiat(sats), 900.0);
      expect(FiatCurrency.ghs.format(sats), 'GH₵ 900.00');

      // 1 BTC = $60,000 USD -> 0.001 BTC = $60 USD
      expect(FiatCurrency.usd.satsToFiat(sats), 60.0);
      expect(FiatCurrency.usd.format(sats), r'$60.00');
    });

    test('Converts fiat back to satoshis accurately', () {
      final satsFromUsd = FiatCurrency.usd.fiatToSats(60.0);
      expect(satsFromUsd, 100000);

      final satsFromNgn = FiatCurrency.ngn.fiatToSats(95000.0);
      expect(satsFromNgn, 100000);
    });

    test('CurrencyNotifier updates active currency', () async {
      final notifier = CurrencyNotifier();
      expect(notifier.state, FiatCurrency.ngn);

      await notifier.setCurrency(FiatCurrency.kes);
      expect(notifier.state, FiatCurrency.kes);

      await notifier.setCurrency(FiatCurrency.usd);
      expect(notifier.state, FiatCurrency.usd);
    });
  });
}
