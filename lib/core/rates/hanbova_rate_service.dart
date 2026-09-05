import '../networking/api_client.dart';
import 'hanbova_rate.dart';

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
}
