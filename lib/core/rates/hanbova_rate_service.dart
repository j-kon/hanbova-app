import '../networking/api_client.dart';
import 'hanbova_rate.dart';

/// Describes one entry in the /rates/hanbova/all response.
class HanbovaMarketRateEntry {
  final String market;
  final String currency;
  final bool available;
  final HanbovaRate? rate;

  const HanbovaMarketRateEntry({
    required this.market,
    required this.currency,
    required this.available,
    this.rate,
  });

  factory HanbovaMarketRateEntry.fromJson(Map<String, dynamic> json) {
    return HanbovaMarketRateEntry(
      market: json['market'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      rate: json['rate'] != null
          ? HanbovaRate.fromJson(json['rate'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HanbovaRateService {
  final ApiClient _apiClient;

  HanbovaRateService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the latest Hanbova platform rate for the specified market and pair.
  Future<HanbovaRate> fetchRate({
    String market = 'NG',
    String asset = 'USDT',
    String currency = 'NGN',
  }) async {
    final queryParams = 'market=$market&asset=$asset&currency=$currency';
    final response = await _apiClient.get('/rates/hanbova?$queryParams');
    return HanbovaRate.fromJson(response);
  }

  /// Fetches all supported market rates in a single request.
  Future<List<HanbovaMarketRateEntry>> fetchAllRates() async {
    final response = await _apiClient.get('/rates/hanbova/all');
    if (response is! List) {
      throw Exception('Unexpected response type from /rates/hanbova/all');
    }
    return (response as List)
        .map((e) => HanbovaMarketRateEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
