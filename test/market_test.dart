import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/market/country_model.dart';

void main() {
  group('M3B.1 Market & Country Domain Models', () {
    test('identityCountry and spendCountry can differ without collision', () {
      // User onboarded in Nigeria (NG), currently traveling in Kenya (KE)
      const context = UserCountryContext(
        identityCountry: 'NG',
        spendCountry: 'KE',
        displayCurrency: FiatCurrency.kes,
      );

      expect(context.identityCountry, 'NG');
      expect(context.spendCountry, 'KE');
      expect(context.displayCurrency, FiatCurrency.kes);

      expect(context.identityCountryInfo.name, 'Nigeria');
      expect(context.identityCountryInfo.flagEmoji, '🇳🇬');
      expect(context.spendCountryInfo.name, 'Kenya');
      expect(context.spendCountryInfo.flagEmoji, '🇰🇪');

      // User changes spend country to Ghana (GH)
      final updated = context.copyWith(
        spendCountry: 'GH',
        displayCurrency: FiatCurrency.ghs,
      );

      // Identity country remains intact
      expect(updated.identityCountry, 'NG');
      expect(updated.spendCountry, 'GH');
      expect(updated.displayCurrency, FiatCurrency.ghs);
      expect(updated.spendCountryInfo.name, 'Ghana');
      expect(updated.spendCountryInfo.flagEmoji, '🇬🇭');
    });

    test('MarketCapabilities deserialization and serialization', () {
      final json = {
        'payouts': true,
        'mobile_money': true,
        'cards': true,
        'airtime': true,
        'data': true,
        'electricity': true,
        'water': true,
        'tv': true,
        'internet': true,
        'esim': true,
      };

      final caps = MarketCapabilities.fromJson(json);
      expect(caps.payouts, isTrue);
      expect(caps.mobileMoney, isTrue);
      expect(caps.cards, isTrue);
      expect(caps.airtime, isTrue);
      expect(caps.data, isTrue);
      expect(caps.electricity, isTrue);
      expect(caps.water, isTrue);
      expect(caps.tv, isTrue);
      expect(caps.internet, isTrue);
      expect(caps.esim, isTrue);

      final outJson = caps.toJson();
      expect(outJson['electricity'], isTrue);
      expect(outJson['esim'], isTrue);
    });

    test('CountryInfo lookup and fallback', () {
      final ke = CountryInfo.findByCode('ke');
      expect(ke.code, 'KE');
      expect(ke.name, 'Kenya');
      expect(ke.defaultCurrency, FiatCurrency.kes);

      final za = CountryInfo.findByCode('ZA');
      expect(za.code, 'ZA');
      expect(za.name, 'South Africa');
      expect(za.defaultCurrency, FiatCurrency.zar);

      final unknown = CountryInfo.findByCode('ZZ');
      expect(unknown.code, 'US'); // Global baseline fallback
    });
  });
}
