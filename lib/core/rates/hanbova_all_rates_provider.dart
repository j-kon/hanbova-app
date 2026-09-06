import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../demo/demo_mode_provider.dart';
import 'hanbova_rate.dart';
import 'hanbova_rate_provider.dart';
import 'hanbova_rate_service.dart';

// ---------------------------------------------------------------------------
// State types
// ---------------------------------------------------------------------------

/// The aggregate status of the all-rates fetch.
enum HanbovaAllRatesStatus { loading, loaded, error }

/// Wraps a single market's rate for the all-rates list.
///
/// Each entry independently tracks its own availability and freshness so a
/// single market being down never brings down the entire view.
class HanbovaMarketRateState {
  final String market;
  final String currency;
  final HanbovaRateStatus status;
  final HanbovaRate? rate;

  const HanbovaMarketRateState({
    required this.market,
    required this.currency,
    required this.status,
    this.rate,
  });

  bool get isAvailable => status != HanbovaRateStatus.unavailable;

  /// Converts this market's rate state into a standard [HanbovaRateState].
  HanbovaRateState toRateState([DateTime? fallbackTime]) {
    return HanbovaRateState(
      status: status,
      rate: rate,
      lastChecked: rate?.updatedAt ?? fallbackTime,
    );
  }

  /// Returns a human-readable flag emoji for the market code.
  String get flagEmoji => _marketFlag(market);

  /// Returns a human-readable country name for the market code.
  String get countryName => _marketName(market);

  static String _marketFlag(String market) {
    return switch (market.toUpperCase()) {
      'NG' => '🇳🇬',
      'KE' => '🇰🇪',
      'GH' => '🇬🇭',
      'ZA' => '🇿🇦',
      'UG' => '🇺🇬',
      'RW' => '🇷🇼',
      'TZ' => '🇹🇿',
      'US' => '🌐',
      _ => '🏳',
    };
  }

  static String _marketName(String market) {
    return switch (market.toUpperCase()) {
      'NG' => 'Nigeria',
      'KE' => 'Kenya',
      'GH' => 'Ghana',
      'ZA' => 'South Africa',
      'UG' => 'Uganda',
      'RW' => 'Rwanda',
      'TZ' => 'Tanzania',
      'US' => 'Global (USD)',
      _ => market,
    };
  }
}

/// The full state object held by [HanbovaAllRatesNotifier].
class HanbovaAllRatesState {
  final HanbovaAllRatesStatus status;
  final List<HanbovaMarketRateState> markets;
  final String? errorMessage;
  final DateTime? lastFetched;

  const HanbovaAllRatesState({
    required this.status,
    this.markets = const [],
    this.errorMessage,
    this.lastFetched,
  });

  const HanbovaAllRatesState.initial()
      : status = HanbovaAllRatesStatus.loading,
        markets = const [],
        errorMessage = null,
        lastFetched = null;

  bool get isLoading => status == HanbovaAllRatesStatus.loading;
  bool get hasData => markets.isNotEmpty;

  /// Find a market rate state by market code (e.g. 'KE') or currency code (e.g. 'KES').
  HanbovaMarketRateState? findBy({String? market, String? currency}) {
    if (market != null) {
      final upper = market.toUpperCase();
      for (final m in markets) {
        if (m.market.toUpperCase() == upper) return m;
      }
    }
    if (currency != null) {
      final upper = currency.toUpperCase();
      for (final m in markets) {
        if (m.currency.toUpperCase() == upper) return m;
      }
    }
    return null;
  }

  HanbovaAllRatesState copyWith({
    HanbovaAllRatesStatus? status,
    List<HanbovaMarketRateState>? markets,
    String? errorMessage,
    DateTime? lastFetched,
  }) {
    return HanbovaAllRatesState(
      status: status ?? this.status,
      markets: markets ?? this.markets,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

// ---------------------------------------------------------------------------
// Canonical ordered markets (mirrors ALL_MARKETS in the Rust backend)
// ---------------------------------------------------------------------------

const _allMarketsOrder = [
  ('NG', 'NGN'),
  ('KE', 'KES'),
  ('GH', 'GHS'),
  ('ZA', 'ZAR'),
  ('UG', 'UGX'),
  ('RW', 'RWF'),
  ('TZ', 'TZS'),
  ('US', 'USD'),
];

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final allHanbovaRatesProvider =
    StateNotifierProvider<HanbovaAllRatesNotifier, HanbovaAllRatesState>((ref) {
  final service = ref.watch(hanbovaRateServiceProvider);
  final isDemo = ref.watch(demoModeProvider).isEnabled;
  return HanbovaAllRatesNotifier(service: service, isDemo: isDemo);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HanbovaAllRatesNotifier extends StateNotifier<HanbovaAllRatesState> {
  final HanbovaRateService _service;
  final bool _isDemo;
  Timer? _pollingTimer;

  HanbovaAllRatesNotifier({
    required HanbovaRateService service,
    required bool isDemo,
    bool autoFetch = true,
  })  : _service = service,
        _isDemo = isDemo,
        super(const HanbovaAllRatesState.initial()) {
    if (_isDemo) {
      state = HanbovaAllRatesState(
        status: HanbovaAllRatesStatus.loaded,
        markets: _buildDemoMarkets(),
        lastFetched: DateTime.now(),
      );
    } else if (autoFetch) {
      fetchAllRates();
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 45)}) {
    _pollingTimer?.cancel();
    _pollingTimer =
        Timer.periodic(interval, (_) => fetchAllRates(silent: true));
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAllRates({bool silent = false}) async {
    if (_isDemo) {
      state = HanbovaAllRatesState(
        status: HanbovaAllRatesStatus.loaded,
        markets: _buildDemoMarkets(),
        lastFetched: DateTime.now(),
      );
      return;
    }

    if (!silent && !state.hasData) {
      state = const HanbovaAllRatesState.initial();
    }

    try {
      final entries = await _service.fetchAllRates();

      // Build per-market state objects, preserving canonical order
      final marketStates = _allMarketsOrder.map((tuple) {
        final (market, currency) = tuple;
        final entry = entries.firstWhere(
          (e) => e.market == market,
          orElse: () => HanbovaMarketRateEntry(
            market: market,
            currency: currency,
            available: false,
          ),
        );

        HanbovaRateStatus rateStatus;
        if (!entry.available || entry.rate == null) {
          rateStatus = HanbovaRateStatus.unavailable;
        } else if (entry.rate!.isStale) {
          rateStatus = HanbovaRateStatus.stale;
        } else if (entry.rate!.isLive) {
          rateStatus = HanbovaRateStatus.live;
        } else {
          rateStatus = HanbovaRateStatus.demo;
        }

        return HanbovaMarketRateState(
          market: market,
          currency: currency,
          status: rateStatus,
          rate: entry.rate,
        );
      }).toList();

      state = HanbovaAllRatesState(
        status: HanbovaAllRatesStatus.loaded,
        markets: marketStates,
        lastFetched: DateTime.now(),
      );
    } catch (e) {
      // If we already have data, preserve it rather than wiping the view
      if (state.hasData) {
        // Mark all non-unavailable markets as stale
        final stalledMarkets = state.markets.map((m) {
          if (m.status == HanbovaRateStatus.unavailable) return m;
          return HanbovaMarketRateState(
            market: m.market,
            currency: m.currency,
            status: HanbovaRateStatus.stale,
            rate: m.rate?.copyWith(isStale: true, isLive: false),
          );
        }).toList();

        state = state.copyWith(
          status: HanbovaAllRatesStatus.loaded,
          markets: stalledMarkets,
        );
      } else {
        state = HanbovaAllRatesState(
          status: HanbovaAllRatesStatus.error,
          errorMessage: 'Platform rates temporarily unavailable',
          lastFetched: DateTime.now(),
        );
      }
    }
  }

  Future<void> refresh() => fetchAllRates(silent: false);

  // ---------------------------------------------------------------------------
  // Demo helpers
  // ---------------------------------------------------------------------------

  static List<HanbovaMarketRateState> _buildDemoMarkets() {
    const demoRates = {
      ('NG', 'NGN'): 1565.00,
      ('KE', 'KES'): 132.50,
      ('GH', 'GHS'): 15.40,
      ('ZA', 'ZAR'): 18.20,
      ('UG', 'UGX'): 3750.00,
      ('RW', 'RWF'): 1310.00,
      ('TZ', 'TZS'): 2680.00,
      ('US', 'USD'): 1.00,
    };

    return _allMarketsOrder.map((tuple) {
      final (market, currency) = tuple;
      final rate = demoRates[(market, currency)] ?? 1.00;

      return HanbovaMarketRateState(
        market: market,
        currency: currency,
        status: HanbovaRateStatus.demo,
        rate: HanbovaRate.demo(
          market: market,
          quote: currency,
          rate: rate,
        ),
      );
    }).toList();
  }
}
