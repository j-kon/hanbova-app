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
  static const _roamEnabledKey = 'hanbova_roam_enabled';

  MarketNotifier(this._apiClient)
      : super(const UserCountryContext(
          identityCountry: 'NG',
          spendCountry: 'NG',
          displayCurrency: FiatCurrency.ngn,
          roamEnabled: false,
        )) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final identity = await _storage.read(key: _identityKey);
      final spend = await _storage.read(key: _spendKey);
      final currencyStr = await _storage.read(key: _currencyKey);
      final roamStr = await _storage.read(key: _roamEnabledKey);

      final newIdentity = identity ?? state.identityCountry;
      final newSpend = spend ?? state.spendCountry;
      final isRoam = roamStr == 'true';
      final currency = currencyStr != null
          ? FiatCurrency.values.firstWhere(
              (c) => c.code == currencyStr,
              orElse: () => CountryInfo.findByCode(newSpend).defaultCurrency,
            )
          : state.displayCurrency;

      state = state.copyWith(
        identityCountry: newIdentity,
        spendCountry: newSpend,
        displayCurrency: currency,
        roamEnabled: isRoam,
      );

      await fetchCapabilities(newSpend);
    } catch (_) {}
  }

  Future<void> setIdentityCountry(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    await _storage.write(key: _identityKey, value: clean);
    state = state.copyWith(identityCountry: clean);
    if (!state.roamEnabled) {
      await setSpendCountry(clean, syncDisplayCurrency: true);
    }
  }

  Future<void> setSpendCountry(String countryCode,
      {bool syncDisplayCurrency = true}) async {
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

  /// Explicitly activates Roam mode for a target destination country.
  Future<void> activateRoam(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    final newCurrency = CountryInfo.findByCode(clean).defaultCurrency;

    await _storage.write(key: _roamEnabledKey, value: 'true');
    await _storage.write(key: _spendKey, value: clean);
    await _storage.write(key: _currencyKey, value: newCurrency.code);

    state = state.copyWith(
      roamEnabled: true,
      spendCountry: clean,
      displayCurrency: newCurrency,
    );

    await fetchCapabilities(clean);
  }

  /// Explicitly turns off Roam mode, restoring spend country and currency to residence country.
  Future<void> deactivateRoam() async {
    final residence = state.identityCountry;
    final residenceCurrency = CountryInfo.findByCode(residence).defaultCurrency;

    await _storage.write(key: _roamEnabledKey, value: 'false');
    await _storage.write(key: _spendKey, value: residence);
    await _storage.write(key: _currencyKey, value: residenceCurrency.code);

    state = state.copyWith(
      roamEnabled: false,
      spendCountry: residence,
      displayCurrency: residenceCurrency,
    );

    await fetchCapabilities(residence);
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
          water:
              clean == 'KE' || clean == 'GH' || clean == 'UG' || clean == 'RW',
          tv: true,
          internet: clean == 'KE' || clean == 'NG' || clean == 'ZA',
          esim: true,
        ),
      );
    }
  }
}
