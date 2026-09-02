import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hanbova_app/core/market/country_model.dart';
import 'package:hanbova_app/core/market/market_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Onboarding & Market Context Journeys', () {
    test(
        'Initial user country context defaults to Kenya (KE) or country of residence',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final market = container.read(marketProvider);
      expect(market.identityCountry, equals('KE'));
      expect(market.spendCountry, equals('KE'));
      expect(market.capabilities.electricity, isTrue);
      expect(market.capabilities.payouts, isTrue);
    });

    test('Selecting Country of Residence in Onboarding sets identityCountry',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(marketProvider.notifier);
      await notifier.setIdentityCountry('NG');

      final updated = container.read(marketProvider);
      expect(updated.identityCountry, equals('NG'));
      expect(updated.identityCountryInfo.name, equals('Nigeria'));
      expect(updated.identityCountryInfo.flagEmoji, equals('🇳🇬'));
      expect(updated.identityCountryInfo.dialCode, equals('+234'));
    });

    test(
        'Travel market switching changes spendCountry while leaving identityCountry intact',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(marketProvider.notifier);
      await notifier.setIdentityCountry('NG'); // User lives in Nigeria
      await notifier.setSpendCountry('GH'); // User is traveling in Ghana

      final state = container.read(marketProvider);
      expect(state.identityCountry, equals('NG'));
      expect(state.spendCountry, equals('GH'));
      expect(state.spendCountryInfo.name, equals('Ghana'));
      expect(state.spendCountryInfo.flagEmoji, equals('🇬🇭'));
      expect(state.displayCurrency.code, equals('GHS'));
    });

    test(
        'Supported countries catalog includes all 6 core African pilot markets',
        () {
      final codes = CountryInfo.supportedCountries.map((c) => c.code).toList();
      expect(codes, containsAll(['KE', 'NG', 'GH', 'ZA', 'UG', 'RW']));
    });
  });
}
