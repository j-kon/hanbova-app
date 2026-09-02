import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/market/country_model.dart';
import 'package:hanbova_app/core/networking/api_client.dart';

final marketProvider =
    StateNotifierProvider<MarketNotifier, UserCountryContext>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MarketNotifier(apiClient);
});

class MarketNotifier extends StateNotifier<UserCountryContext> {
  final ApiClient _apiClient;
  static const _storage = FlutterSecureStorage();

  static const _identityKey = 'hanbova_identity_country';
  static const _spendKey = 'hanbova_spend_country';
  static const _currencyKey = 'hanbova_display_currency';

  MarketNotifier(this._apiClient)
      : super(const UserCountryContext(
          identityCountry: 'KE',
          spendCountry: 'KE',
          displayCurrency: FiatCurrency.kes,
        )) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final identity = await _storage.read(key: _identityKey) ?? 'KE';
      final spend = await _storage.read(key: _spendKey) ?? 'KE';
      final currencyStr = await _storage.read(key: _currencyKey) ?? 'KES';

      final currency = FiatCurrency.values.firstWhere(
        (c) => c.code == currencyStr,
        orElse: () => CountryInfo.findByCode(spend).defaultCurrency,
      );

      state = state.copyWith(
        identityCountry: identity,
        spendCountry: spend,
        displayCurrency: currency,
      );

      await fetchCapabilities(spend);
    } catch (_) {}
  }

  Future<void> setIdentityCountry(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    await _storage.write(key: _identityKey, value: clean);
    state = state.copyWith(identityCountry: clean);
  }

  Future<void> setSpendCountry(String countryCode, {bool syncDisplayCurrency = true}) async {
    final clean = countryCode.trim().toUpperCase();
    await _storage.write(key: _spendKey, value: clean);

    FiatCurrency newCurrency = state.displayCurrency;
    if (syncDisplayCurrency) {
      newCurrency = CountryInfo.findByCode(clean).defaultCurrency;
      await _storage.write(key: _currencyKey, value: newCurrency.code);
    }

    state = state.copyWith(
      spendCountry: clean,
      displayCurrency: newCurrency,
    );

    await fetchCapabilities(clean);
  }

  Future<void> setDisplayCurrency(FiatCurrency currency) async {
    await _storage.write(key: _currencyKey, value: currency.code);
    state = state.copyWith(displayCurrency: currency);
  }

  Future<void> fetchCapabilities(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    try {
      final data = await _apiClient.get('/markets/$clean/capabilities');
      final capsJson = data['capabilities'] as Map<String, dynamic>? ?? {};
      final caps = MarketCapabilities.fromJson(capsJson);
      if (state.spendCountry == clean) {
        state = state.copyWith(capabilities: caps);
      }
    } catch (_) {
      // Fallback default capabilities for known countries
      state = state.copyWith(
        capabilities: MarketCapabilities(
          payouts: true,
          mobileMoney: clean != 'NG' && clean != 'ZA',
          cards: true,
          airtime: true,
          data: true,
          electricity: true,
          water: clean == 'KE' || clean == 'GH' || clean == 'UG' || clean == 'RW',
          tv: true,
          internet: clean == 'KE' || clean == 'NG' || clean == 'ZA',
          esim: true,
        ),
      );
    }
  }
}
