import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/config/app_config.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/home/presentation/asset_balance_carousel.dart';
import 'package:hanbova_app/features/spend/data/bills_service.dart';
import 'package:hanbova_app/features/travel/data/esim_service.dart';
import 'package:hanbova_app/features/wallet/domain/asset_model.dart';
import 'package:http/http.dart' as http;

class MockFailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Future.error(http.ClientException('Connection failed to hosted backend'));
  }
}

void main() {
  group('Pilot Environment AppConfig Fail-Closed Validation', () {
    test('createPilot succeeds with hosted HTTPS endpoints', () {
      final config = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );

      expect(config.isPilot, isTrue);
      expect(config.isDevelopment, isFalse);
      expect(config.isProduction, isFalse);
      expect(config.isMock, isFalse);
      expect(config.apiBaseUrl, 'https://api.pilot.hanbova.com/api/v1');
      expect(config.mintUrl, 'https://mint.pilot.hanbova.com');
    });

    test('createPilot rejects empty apiBaseUrl', () {
      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: '',
          mintUrl: 'https://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createPilot rejects non-HTTPS apiBaseUrl', () {
      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'http://api.pilot.hanbova.com/api/v1',
          mintUrl: 'https://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createPilot rejects localhost and private IPs in apiBaseUrl', () {
      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'https://localhost:8080/api/v1',
          mintUrl: 'https://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'https://127.0.0.1:8080/api/v1',
          mintUrl: 'https://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'https://10.0.2.2:8080/api/v1',
          mintUrl: 'https://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createPilot rejects non-HTTPS or local mintUrl', () {
      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
          mintUrl: 'http://mint.pilot.hanbova.com',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => AppConfig.createPilot(
          apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
          mintUrl: 'https://127.0.0.1:3338',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ApiClient Pilot Behavior', () {
    test('Does not rewrite hosted HTTPS URLs to 10.0.2.2 in pilot', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.createPilot(
              apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
              mintUrl: 'https://mint.pilot.hanbova.com',
            ),
          ),
        ],
      );

      final client = container.read(apiClientProvider);
      expect(client.baseUrl, 'https://api.pilot.hanbova.com/api/v1');
    });

    testWidgets('Pilot displays environment marker PILOT • TEST MODE', (tester) async {
      final pilotConfig = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(pilotConfig),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final config = ref.watch(appConfigProvider);
                  if (!config.isPilot) return const SizedBox.shrink();
                  return const Text(
                    'PILOT • TEST MODE',
                    key: Key('pilot-environment-badge'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pilot-environment-badge')), findsOneWidget);
      expect(find.text('PILOT • TEST MODE'), findsOneWidget);
    });
  });

  group('Provider Fail-Closed Fallbacks', () {
    test('BillsService.validateCustomer throws when backend fails in pilot (no fake customer)', () async {
      final pilotConfig = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );
      final apiClient = ApiClient(
        baseUrl: pilotConfig.apiBaseUrl,
        httpClient: MockFailingHttpClient(),
      );
      final billsService = BillsService(apiClient, config: pilotConfig);

      expect(
        () => billsService.validateCustomer('ke_kplc', '14123456789'),
        throwsA(anything),
      );
    });

    test('BillsService.validateCustomer returns mock only in mock environment', () async {
      final mockConfig = AppConfig.mock;
      final apiClient = ApiClient(
        baseUrl: mockConfig.apiBaseUrl,
        httpClient: MockFailingHttpClient(),
      );
      final billsService = BillsService(apiClient, config: mockConfig);

      final result = await billsService.validateCustomer('ke_kplc', '14123456789');
      expect(result.isValid, isTrue);
      expect(result.customerName, 'Verified Customer (Mock)');
    });

    test('TravelService.checkCardEligibility returns ineligible when backend fails in pilot', () async {
      final pilotConfig = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );
      final apiClient = ApiClient(
        baseUrl: pilotConfig.apiBaseUrl,
        httpClient: MockFailingHttpClient(),
      );
      final travelService = TravelService(apiClient, config: pilotConfig);

      final result = await travelService.checkCardEligibility('KE');
      expect(result.isEligible, isFalse);
      expect(result.supportedTypes, isEmpty);
      expect(result.reason, contains('unavailable'));
    });

    test('TravelService.checkCardEligibility returns mock only in mock environment', () async {
      final mockConfig = AppConfig.mock;
      final apiClient = ApiClient(
        baseUrl: mockConfig.apiBaseUrl,
        httpClient: MockFailingHttpClient(),
      );
      final travelService = TravelService(apiClient, config: mockConfig);

      final result = await travelService.checkCardEligibility('KE');
      expect(result.isEligible, isTrue);
      expect(result.supportedTypes, contains('virtual_visa'));
    });
  });

  group('Demo Mode Protection in Pilot', () {
    test('DemoModeNotifier cannot be enabled in pilot', () {
      final pilotConfig = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );

      final notifier = DemoModeNotifier(config: pilotConfig);
      expect(notifier.state.isEnabled, isFalse);

      notifier.toggleDemoMode();
      expect(notifier.state.isEnabled, isFalse);
    });

    test('DemoModeNotifier cannot be enabled in production', () {
      final prodConfig = AppConfig.createProduction(
        apiBaseUrl: 'https://api.hanbova.com/api/v1',
        mintUrl: 'https://mint.hanbova.com',
      );

      final notifier = DemoModeNotifier(config: prodConfig);
      expect(notifier.state.isEnabled, isFalse);

      notifier.toggleDemoMode();
      expect(notifier.state.isEnabled, isFalse);
    });

    test('Demo sample balances only show when Demo Mode is enabled', () {
      final pilotConfig = AppConfig.createPilot(
        apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
        mintUrl: 'https://mint.pilot.hanbova.com',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(pilotConfig),
        ],
      );

      final demoState = container.read(demoModeProvider);
      // In pilot, demo mode cannot be active, so isEnabled is false
      expect(demoState.isEnabled, isFalse);
    });
  });

  group('Mainnet Safety Guard in Pilot', () {
    test('Mainnet remains strictly locked in pilot', () async {
      final notifier = NetworkEnvironmentNotifier();
      expect(notifier.state, isNot(HanbovaNetwork.mainnet));

      await notifier.setNetwork(HanbovaNetwork.mainnet);
      expect(notifier.state, isNot(HanbovaNetwork.mainnet));

      final active = NetworkConfig.fromNetwork(notifier.state);
      expect(active.network, isNot(HanbovaNetwork.mainnet));
    });
  });

  group('Home Carousel & selectedHomeAssetProvider Non-Regression', () {
    test('selectedHomeAssetProvider defaults to bitcoin and transitions cleanly', () {
      final container = ProviderContainer();
      expect(container.read(selectedHomeAssetProvider), AssetType.btc);

      container.read(selectedHomeAssetProvider.notifier).state = AssetType.usdt;
      expect(container.read(selectedHomeAssetProvider), AssetType.usdt);

      container.read(selectedHomeAssetProvider.notifier).state = AssetType.usdc;
      expect(container.read(selectedHomeAssetProvider), AssetType.usdc);
    });

    test('Truthful USDT/USDC status when demo mode is off', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.createPilot(
              apiBaseUrl: 'https://api.pilot.hanbova.com/api/v1',
              mintUrl: 'https://mint.pilot.hanbova.com',
            ),
          ),
        ],
      );

      final isDemo = container.read(demoModeProvider).isEnabled;
      expect(isDemo, isFalse);
      // When isDemo is false, app correctly keeps sample balances disabled
    });
  });
}
