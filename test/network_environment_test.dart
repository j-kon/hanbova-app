import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/network/network_environment.dart';

void main() {
  group('Network Environment & Safety Tests', () {
    test('Default environment is local development', () {
      final config = NetworkConfig.local;
      expect(config.network, HanbovaNetwork.local);
      expect(config.isTestMode, isTrue);
      expect(config.isEnabled, isTrue);
      expect(config.defaultMintUrl, 'http://127.0.0.1:3338');
    });

    test('Cashu Test configuration uses public test mint', () {
      final config = NetworkConfig.cashuTest;
      expect(config.network, HanbovaNetwork.cashuTest);
      expect(config.isTestMode, isTrue);
      expect(config.isEnabled, isTrue);
      expect(config.defaultMintUrl, 'https://testnut.cashu.space');
      expect(config.storagePrefix, 'wallet_cashu_test');
    });

    test('Mainnet configuration is strictly disabled for safety in this build',
        () async {
      final config = NetworkConfig.mainnet;
      expect(config.network, HanbovaNetwork.mainnet);
      expect(config.isEnabled, isFalse);
      expect(config.isTestMode, isFalse);
      expect(config.storagePrefix, 'wallet_mainnet');

      final notifier = NetworkEnvironmentNotifier();
      // Attempting to set Mainnet is blocked by safety guard
      await notifier.setNetwork(HanbovaNetwork.mainnet);
      expect(notifier.state, HanbovaNetwork.local);
    });

    test(
        'Switching between Local and CashuTest succeeds while Mainnet is locked',
        () async {
      final notifier = NetworkEnvironmentNotifier();
      expect(notifier.state, HanbovaNetwork.local);

      await notifier.setNetwork(HanbovaNetwork.cashuTest);
      expect(notifier.state, HanbovaNetwork.cashuTest);

      await notifier.setNetwork(HanbovaNetwork.local);
      expect(notifier.state, HanbovaNetwork.local);
    });
  });
}
