import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/security/presentation/backup_seed_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'Milestone 3B.1 / Milestone 5: Real-Sats Safety Gate & Mainnet Pilot Tests',
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

      // Attempting to switch to Mainnet without pilot override is ignored by safety guard
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
      expect(pilot.maxWalletBalanceSats, 10000);
      expect(pilot.maxDepositSats, 10000);
      expect(pilot.maxSendSats, 5000);
      expect(pilot.defaultMintUrl, 'https://mint.minibits.cash/Bitcoin');
      expect(pilot.displayName, contains('Pilot'));
    });

    test(
        'Active Network Config Provider correctly resolves pilot override & allowlisted mint',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default: Local testnet
      final initialConfig = container.read(activeNetworkConfigProvider);
      expect(initialConfig.network, HanbovaNetwork.local);
      expect(initialConfig.isPilot, isFalse);

      // Select custom testnut mint
      container.read(selectedMintUrlProvider.notifier).state =
          'https://testnut.cashu.space';
      expect(container.read(selectedMintUrlProvider),
          'https://testnut.cashu.space');

      // Enable Controlled Mainnet Pilot override
      container.read(mainnetPilotOverrideProvider.notifier).state = true;
      container.read(networkEnvironmentProvider.notifier).setNetwork(
            HanbovaNetwork.mainnet,
            pilotOverride: true,
          );

      final pilotConfig = container.read(activeNetworkConfigProvider);
      expect(pilotConfig.isPilot, isTrue);
      expect(pilotConfig.network, HanbovaNetwork.mainnet);
      expect(pilotConfig.defaultMintUrl, 'https://mint.minibits.cash/Bitcoin');
      expect(pilotConfig.maxWalletBalanceSats, 10000);
      expect(pilotConfig.maxSendSats, 5000);

      // In pilot mode, effective mint URL MUST ALWAYS be Minibits allowlist
      final effectiveMintUrl = pilotConfig.isPilot
          ? pilotConfig.defaultMintUrl
          : (container.read(selectedMintUrlProvider) ??
              pilotConfig.defaultMintUrl);
      expect(effectiveMintUrl, 'https://mint.minibits.cash/Bitcoin');
    });

    test('MintQuoteStatusResult correctly parses quote state transitions', () {
      final unpaid = MintQuoteStatusResult.fromStateString('UNPAID');
      expect(unpaid.status, MintQuoteStatus.unpaid);
      expect(unpaid.isPaid, isFalse);

      final paid = MintQuoteStatusResult.fromStateString('PAID');
      expect(paid.status, MintQuoteStatus.paid);
      expect(paid.isPaid, isTrue);

      final issued = MintQuoteStatusResult.fromStateString('ISSUED');
      expect(issued.status, MintQuoteStatus.issued);
      expect(issued.isPaid, isFalse);

      final expired = MintQuoteStatusResult.fromStateString('EXPIRED');
      expect(expired.status, MintQuoteStatus.expired);
      expect(expired.isPaid, isFalse);
    });
  });
}
