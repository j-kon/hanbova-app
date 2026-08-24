import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/security/presentation/backup_seed_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 5: Public Mainnet Beta Safety & Network Architecture Tests', () {
    test('NetworkConfig provides distinct storage prefixes and valid URLs for all networks', () {
      final local = NetworkConfig.fromNetwork(HanbovaNetwork.local);
      final testnet = NetworkConfig.fromNetwork(HanbovaNetwork.cashuTest);
      final mainnet = NetworkConfig.fromNetwork(HanbovaNetwork.mainnet);

      // Verify storage prefix isolation
      expect(local.storagePrefix, 'wallet_local');
      expect(testnet.storagePrefix, 'wallet_cashu_test');
      expect(mainnet.storagePrefix, 'wallet_mainnet');

      // Verify all prefixes are distinct
      final prefixes = {local.storagePrefix, testnet.storagePrefix, mainnet.storagePrefix};
      expect(prefixes.length, 3);

      // Verify Mainnet settings
      expect(mainnet.isTestMode, isFalse);
      expect(mainnet.isEnabled, isTrue);
      expect(mainnet.defaultMintUrl.startsWith('https://'), isTrue);
      expect(mainnet.displayName, 'Bitcoin Mainnet');
    });

    test('NetworkEnvironmentNotifier state transitions correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkEnvironmentProvider.notifier);

      expect(container.read(networkEnvironmentProvider), HanbovaNetwork.local);

      await notifier.setNetwork(HanbovaNetwork.cashuTest);
      expect(container.read(networkEnvironmentProvider), HanbovaNetwork.cashuTest);

      await notifier.setNetwork(HanbovaNetwork.mainnet);
      expect(container.read(networkEnvironmentProvider), HanbovaNetwork.mainnet);
    });

    test('WalletBackupStatusProvider defaults to false until backup completed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(walletBackupStatusProvider), isFalse);

      container.read(walletBackupStatusProvider.notifier).state = true;
      expect(container.read(walletBackupStatusProvider), isTrue);
    });
  });
}
