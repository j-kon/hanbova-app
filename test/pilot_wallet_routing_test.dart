import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/config/app_config.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'hanbova_network_environment': 'local',
      }));

  final pilot = AppConfig.createPilot(
    apiBaseUrl: 'https://api.pilot.example.com/api/v1',
    mintUrl: 'https://mint.pilot.example.com',
  );

  test('private pilot wallet environment fits the backend persistence contract',
      () {
    final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(pilot)]);
    addTearDown(container.dispose);
    final environment =
        container.read(activeNetworkConfigProvider).storagePrefix;
    // This namespace is sent to the API and stored in VARCHAR(50) columns.
    expect(environment.length, lessThanOrEqualTo(50));
  });

  test('private pilot build cannot unlock mainnet with the legacy flag', () {
    if (const String.fromEnvironment('HANBOVA_ENV') == 'pilot' ||
        const String.fromEnvironment('HANBOVA_ENV') == 'production') {
      expect(NetworkConfig.isMainnetPilotBuild, isFalse);
      expect(
          NetworkConfig.fromNetwork(HanbovaNetwork.mainnet).isEnabled, isFalse);
    }
  });

  test(
      'private pilot selects its configured test mint and ignores saved local network',
      () async {
    final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(pilot)]);
    addTearDown(container.dispose);
    final initial = container.read(activeNetworkConfigProvider);
    expect(initial.defaultMintUrl, 'https://mint.pilot.example.com');
    expect(initial.network, HanbovaNetwork.cashuTest);
    expect(initial.isTestMode, isTrue);
    expect(initial.isEnabled, isTrue);
    expect(initial.storagePrefix, isNot(NetworkConfig.cashuTest.storagePrefix));
    await container.pump();
    for (final network in HanbovaNetwork.values) {
      await container
          .read(networkEnvironmentProvider.notifier)
          .setNetwork(network);
      expect(
          container.read(networkEnvironmentProvider), HanbovaNetwork.cashuTest);
      expect(container.read(activeNetworkConfigProvider).defaultMintUrl,
          'https://mint.pilot.example.com');
    }
  });

  test('private pilot wallet storage is isolated by API and mint endpoints',
      () {
    final prefixes = <String>{};
    for (final config in [
      pilot,
      AppConfig.createPilot(
          apiBaseUrl: 'https://other-api.example.com/api/v1',
          mintUrl: pilot.mintUrl),
      AppConfig.createPilot(
          apiBaseUrl: pilot.apiBaseUrl,
          mintUrl: 'https://other-mint.example.com'),
    ]) {
      final container = ProviderContainer(
          overrides: [appConfigProvider.overrideWithValue(config)]);
      addTearDown(container.dispose);
      prefixes.add(container.read(activeNetworkConfigProvider).storagePrefix);
    }
    expect(prefixes.length, 3);
  });
}
