import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/security/presentation/backup_seed_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 5: Public Mainnet Beta Safety & Network Architecture Tests',
      () {
    test(
        'NetworkConfig provides distinct storage prefixes and valid URLs for all networks',
        () {
      final local = NetworkConfig.fromNetwork(HanbovaNetwork.local);
      final testnet = NetworkConfig.fromNetwork(HanbovaNetwork.cashuTest);
      final mainnet = NetworkConfig.fromNetwork(HanbovaNetwork.mainnet);

      // Verify storage prefix isolation
      expect(local.storagePrefix, 'wallet_local');
      expect(testnet.storagePrefix, 'wallet_cashu_test');
      expect(mainnet.storagePrefix, 'wallet_mainnet');

      // Verify all prefixes are distinct
      final prefixes = {
        local.storagePrefix,
        testnet.storagePrefix,
        mainnet.storagePrefix
      };
      expect(prefixes.length, 3);

      // Verify Mainnet settings are locked for safety
      expect(mainnet.isTestMode, isFalse);
      expect(mainnet.isEnabled, isFalse);
      expect(mainnet.displayName, contains('Locked'));
    });

    test(
        'NetworkEnvironmentNotifier state transitions correctly between test networks',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkEnvironmentProvider.notifier);

      expect(container.read(networkEnvironmentProvider), HanbovaNetwork.local);

      await notifier.setNetwork(HanbovaNetwork.cashuTest);
      expect(
          container.read(networkEnvironmentProvider), HanbovaNetwork.cashuTest);

      // Attempting to switch to Mainnet is ignored by safety guard
      await notifier.setNetwork(HanbovaNetwork.mainnet);
      expect(
          container.read(networkEnvironmentProvider), HanbovaNetwork.cashuTest);
    });

    test('WalletBackupStatusProvider defaults to false until backup completed',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(walletBackupStatusProvider), isFalse);

      container.read(walletBackupStatusProvider.notifier).state = true;
      expect(container.read(walletBackupStatusProvider), isTrue);
    });

    test(
        'Controlled Mainnet Pilot config enforces strict caps and allowlisted mint',
        () {
      final pilot =
          NetworkConfig.fromNetwork(HanbovaNetwork.mainnet, pilotActive: true);
      expect(pilot.isPilot, isTrue);
      expect(pilot.isEnabled, isTrue);
      expect(pilot.maxDepositSats, 10000);
      expect(pilot.maxSendSats, 5000);
      expect(pilot.defaultMintUrl, 'https://mint.minibits.cash/Bitcoin');
      expect(pilot.displayName, contains('Pilot'));
    });
  });
}
