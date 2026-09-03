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
  final ApiClient? _apiClient;
  static const _storage = FlutterSecureStorage();

  static const _residenceKey = 'hanbova_residence_country';
  static const _identityKey = 'hanbova_identity_country';
  static const _activeMarketKey = 'hanbova_active_market';
  static const _spendKey = 'hanbova_spend_country';
  static const _currencyKey = 'hanbova_display_currency';
  static const _roamEnabledKey = 'hanbova_roam_enabled';

  MarketNotifier([this._apiClient])
      : super(const UserCountryContext(
          residenceCountry: 'NG',
          activeMarket: 'NG',
          displayCurrency: FiatCurrency.ngn,
          roamEnabled: false,
          capabilities: MarketCapabilities(
            bitcoin: true,
            cashu: true,
            protectedPayments: true,
            stablecoin: false,
            airtime: true,
            data: true,
            electricity: true,
            water: true,
            tv: true,
            internet: true,
            bankPayout: true,
            mobileMoney: false,
            virtualCards: true,
            esim: true,
          ),
        )) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final residence = (await _storage.read(key: _residenceKey)) ??
          (await _storage.read(key: _identityKey));
      final market = (await _storage.read(key: _activeMarketKey)) ??
          (await _storage.read(key: _spendKey));
      final currencyStr = await _storage.read(key: _currencyKey);
      final roamStr = await _storage.read(key: _roamEnabledKey);

      final newResidence = residence ?? state.residenceCountry;
      final isRoam = roamStr == 'true';
      final newMarket = isRoam ? (market ?? newResidence) : newResidence;

      final defaultCurr = CountryInfo.findByCode(newMarket).defaultCurrency;
      final currency = currencyStr != null
          ? FiatCurrency.values.firstWhere(
              (c) => c.code == currencyStr,
              orElse: () => defaultCurr,
            )
          : defaultCurr;

      state = state.copyWith(
        residenceCountry: newResidence,
        activeMarket: newMarket,
        displayCurrency: currency,
        roamEnabled: isRoam,
        capabilities: MarketCapabilities.forMarket(newMarket),
      );

      await fetchCapabilities(newMarket);
    } catch (_) {}
  }

  /// Sets the user's permanent legal Country of Residence.
  Future<void> setResidenceCountry(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    await _storage.write(key: _residenceKey, value: clean);
    await _storage.write(key: _identityKey, value: clean);

    state = state.copyWith(residenceCountry: clean);

    // When Roam is NOT active, active market follows residence country
    if (!state.roamEnabled) {
      await setActiveMarket(clean, syncDisplayCurrency: true);
    }
  }

  /// Backward-compatible alias for setResidenceCountry
  Future<void> setIdentityCountry(String countryCode) =>
      setResidenceCountry(countryCode);

  /// Sets the active market context.
  Future<void> setActiveMarket(String countryCode,
      {bool syncDisplayCurrency = true}) async {
    final clean = countryCode.trim().toUpperCase();
    await _storage.write(key: _activeMarketKey, value: clean);
    await _storage.write(key: _spendKey, value: clean);

    FiatCurrency newCurrency = state.displayCurrency;
    if (syncDisplayCurrency) {
      newCurrency = CountryInfo.findByCode(clean).defaultCurrency;
      await _storage.write(key: _currencyKey, value: newCurrency.code);
    }

    state = state.copyWith(
      activeMarket: clean,
      displayCurrency: newCurrency,
      capabilities: MarketCapabilities.forMarket(clean),
    );

    await fetchCapabilities(clean);
  }

  /// Backward-compatible alias for setActiveMarket
  Future<void> setSpendCountry(String countryCode,
          {bool syncDisplayCurrency = true}) =>
      setActiveMarket(countryCode, syncDisplayCurrency: syncDisplayCurrency);

  /// Explicitly activates Roam mode for a target destination country.
  /// Residence country remains completely unchanged.
  Future<void> activateRoam(String targetCountryCode) async {
    final clean = targetCountryCode.trim().toUpperCase();
    final newCurrency = CountryInfo.findByCode(clean).defaultCurrency;

    await _storage.write(key: _roamEnabledKey, value: 'true');
    await _storage.write(key: _activeMarketKey, value: clean);
    await _storage.write(key: _spendKey, value: clean);
    await _storage.write(key: _currencyKey, value: newCurrency.code);

    state = state.copyWith(
      roamEnabled: true,
      activeMarket: clean,
      displayCurrency: newCurrency,
      capabilities: MarketCapabilities.forMarket(clean),
    );

    await fetchCapabilities(clean);
  }

  /// Explicitly turns off Roam mode, restoring active market and display currency
  /// to the user's permanent Country of Residence.
  Future<void> deactivateRoam() async {
    final residence = state.residenceCountry;
    final residenceCurrency = CountryInfo.findByCode(residence).defaultCurrency;

    await _storage.write(key: _roamEnabledKey, value: 'false');
    await _storage.write(key: _activeMarketKey, value: residence);
    await _storage.write(key: _spendKey, value: residence);
    await _storage.write(key: _currencyKey, value: residenceCurrency.code);

    state = state.copyWith(
      roamEnabled: false,
      activeMarket: residence,
      displayCurrency: residenceCurrency,
      capabilities: MarketCapabilities.forMarket(residence),
    );

    await fetchCapabilities(residence);
  }

  Future<void> setDisplayCurrency(FiatCurrency currency) async {
    await _storage.write(key: _currencyKey, value: currency.code);
    state = state.copyWith(displayCurrency: currency);
  }

  Future<void> fetchCapabilities(String countryCode) async {
    final clean = countryCode.trim().toUpperCase();
    final client = _apiClient;
    if (client != null) {
      try {
        final data = await client.get('/markets/$clean/capabilities');
        final capsJson = data['capabilities'] as Map<String, dynamic>? ?? {};
        final caps = MarketCapabilities.fromJson(capsJson);
        if (state.activeMarket == clean) {
          state = state.copyWith(capabilities: caps);
        }
        return;
      } catch (_) {}
    }

    // Deterministic capability matrix for frontend development
    if (state.activeMarket == clean) {
      state = state.copyWith(
        capabilities: MarketCapabilities.forMarket(clean),
      );
    }
  }
}
