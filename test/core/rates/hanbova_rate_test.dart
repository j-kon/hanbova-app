import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/rates/hanbova_rate.dart';
import 'package:hanbova_app/core/rates/hanbova_rate_provider.dart';
import 'package:hanbova_app/core/rates/hanbova_rate_service.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('HanbovaRate Model Tests', () {
    test('parses from JSON correctly', () {
      final json = {
        'market': 'NG',
        'base': 'USD',
        'quote': 'NGN',
        'display': r'$1 = ₦1,365.00',
        'settlement_asset': 'USDT',
        'rate': 1365.00,
        'provider': 'bitnob',
        'is_live': true,
        'is_stale': false,
        'updated_at': '2026-09-05T20:00:00Z',
        'expires_at': null,
      };

      final rate = HanbovaRate.fromJson(json);
      assert(rate.market == 'NG');
      assert(rate.base == 'USD');
      assert(rate.quote == 'NGN');
      assert(rate.display == r'$1 = ₦1,365.00');
      assert(rate.settlementAsset == 'USDT');
      assert(rate.rate == 1365.00);
      assert(rate.provider == 'bitnob');
      assert(rate.isLive == true);
      assert(rate.isStale == false);
    });

    test('formatDisplay produces truthful platform rate strings', () {
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'NGN', rate: 1365.0),
        r'$1 = ₦1,365.00',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'KES', rate: 130.5),
        r'$1 = KSh 130.50',
      );
      expect(
        HanbovaRate.formatDisplay(base: 'USD', quote: 'GHS', rate: 15.2),
        r'$1 = GH₵ 15.20',
      );
    });

    test('demo rate is explicitly NOT marked live', () {
      final demo = HanbovaRate.demo();
      expect(demo.isLive, false);
      expect(demo.isStale, false);
      expect(demo.settlementAsset, 'USDT');
      expect(demo.quote, 'NGN');
      expect(demo.display, r'$1 = ₦1,365.00');
    });
  });

  group('HanbovaRateService Tests', () {
    test('fetches rate from API endpoint', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/api/v1/rates/hanbova');
        expect(request.url.queryParameters['market'], 'NG');
        return http.Response(
          '''
          {
            "market": "NG",
            "base": "USD",
            "quote": "NGN",
            "display": "\$1 = ₦1,365.00",
            "settlement_asset": "USDT",
            "rate": 1365.00,
            "provider": "bitnob",
            "is_live": true,
            "is_stale": false,
            "updated_at": "2026-09-05T20:00:00Z"
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8080/api/v1',
        httpClient: mockClient,
      );
      final service = HanbovaRateService(apiClient: apiClient);

      final rate = await service.fetchRate(market: 'NG');
      expect(rate.rate, 1365.00);
      expect(rate.isLive, true);
      expect(rate.isStale, false);
    });
  });

  group('HanbovaRateNotifier State Transitions', () {
    test('initializes with demo state when isDemo is true', () {
      final mockClient = MockHttpClient((_) async => http.Response('{}', 200));
      final apiClient = ApiClient(baseUrl: '', httpClient: mockClient);
      final service = HanbovaRateService(apiClient: apiClient);

      final notifier = HanbovaRateNotifier(service: service, isDemo: true);
      expect(notifier.state.status, HanbovaRateStatus.demo);
      expect(notifier.state.rate, isNotNull);
      expect(notifier.state.rate!.isLive, false);
      expect(notifier.state.isDemo, true);
    });

    test('transitions to unavailable when API fails with no cache', () async {
      final mockClient = MockHttpClient((_) async => http.Response(
            '{"error":"Rate temporarily unavailable","code":"rate_unavailable"}',
            503,
            headers: {'content-type': 'application/json'},
          ));
      final apiClient = ApiClient(baseUrl: '', httpClient: mockClient);
      final service = HanbovaRateService(apiClient: apiClient);

      final notifier = HanbovaRateNotifier(
        service: service,
        isDemo: false,
        autoFetch: false,
      );
      await notifier.fetchRate();

      expect(notifier.state.status, HanbovaRateStatus.unavailable);
      expect(notifier.state.isUnavailable, true);
      expect(notifier.state.errorMessage, 'Rate temporarily unavailable');
    });

    test('preserves cached rate as stale when subsequent fetch fails',
        () async {
      var callCount = 0;
      final mockClient = MockHttpClient((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            '''
            {
              "market": "NG",
              "base": "USD",
              "quote": "NGN",
              "display": "\$1 = ₦1,365.00",
              "settlement_asset": "USDT",
              "rate": 1365.00,
              "provider": "bitnob",
              "is_live": true,
              "is_stale": false,
              "updated_at": "2026-09-05T20:00:00Z"
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            '{"error":"Temporarily down"}',
            503,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final apiClient = ApiClient(baseUrl: '', httpClient: mockClient);
      final service = HanbovaRateService(apiClient: apiClient);
      final notifier = HanbovaRateNotifier(
        service: service,
        isDemo: false,
        autoFetch: false,
      );

      // First call succeeds -> live
      await notifier.fetchRate();
      expect(notifier.state.status, HanbovaRateStatus.live);
      expect(notifier.state.rate!.rate, 1365.0);

      // Second call fails -> transitions to stale, keeping rate
      await notifier.fetchRate();
      expect(notifier.state.status, HanbovaRateStatus.stale);
      expect(notifier.state.isStale, true);
      expect(notifier.state.rate!.rate, 1365.0);
      expect(notifier.state.rate!.isStale, true);
    });
  });
}
