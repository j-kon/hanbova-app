import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../demo/demo_mode_provider.dart';
import '../networking/api_client.dart';
import 'hanbova_rate.dart';
import 'hanbova_rate_service.dart';

final hanbovaRateServiceProvider = Provider<HanbovaRateService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HanbovaRateService(apiClient: apiClient);
});

final hanbovaRateProvider =
    StateNotifierProvider<HanbovaRateNotifier, HanbovaRateState>((ref) {
  final service = ref.watch(hanbovaRateServiceProvider);
  final isDemo = ref.watch(demoModeProvider).isEnabled;
  return HanbovaRateNotifier(service: service, isDemo: isDemo);
});

class HanbovaRateNotifier extends StateNotifier<HanbovaRateState> {
  final HanbovaRateService _service;
  final bool _isDemo;
  Timer? _pollingTimer;

  HanbovaRateNotifier({
    required HanbovaRateService service,
    required bool isDemo,
    bool autoFetch = true,
  })  : _service = service,
        _isDemo = isDemo,
        super(const HanbovaRateState.initial()) {
    if (_isDemo) {
      state = HanbovaRateState(
        status: HanbovaRateStatus.demo,
        rate: HanbovaRate.demo(),
        lastChecked: DateTime.now(),
      );
    } else if (autoFetch) {
      fetchRate();
      // Periodically refresh indicative rate in the background every 45s
      _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        fetchRate(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Fetches the latest Hanbova platform rate.
  /// If [silent] is true, avoids switching to full loading UI to prevent flashing.
  Future<void> fetchRate({
    bool silent = false,
    String market = 'NG',
    String asset = 'USDT',
    String currency = 'NGN',
  }) async {
    if (_isDemo) {
      state = HanbovaRateState(
        status: HanbovaRateStatus.demo,
        rate: HanbovaRate.demo(),
        lastChecked: DateTime.now(),
      );
      return;
    }

    if (!silent && state.rate == null) {
      state = state.copyWith(status: HanbovaRateStatus.loading);
    }

    try {
      final fetchedRate = await _service.fetchRate(
        market: market,
        asset: asset,
        currency: currency,
      );

      final status = fetchedRate.isStale
          ? HanbovaRateStatus.stale
          : (fetchedRate.isLive
              ? HanbovaRateStatus.live
              : HanbovaRateStatus.demo);

      state = HanbovaRateState(
        status: status,
        rate: fetchedRate,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      // If we already have a rate cached locally, preserve it as stale
      if (state.rate != null) {
        state = state.copyWith(
          status: HanbovaRateStatus.stale,
          rate: state.rate!.copyWith(isStale: true, isLive: false),
          lastChecked: DateTime.now(),
        );
      } else {
        state = HanbovaRateState(
          status: HanbovaRateStatus.unavailable,
          rate: null,
          errorMessage: 'Rate temporarily unavailable',
          lastChecked: DateTime.now(),
        );
      }
    }
  }

  /// Manually trigger a refresh (e.g. from pull-to-refresh or retry button).
  Future<void> refresh() => fetchRate(silent: false);
}
