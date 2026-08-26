import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/mint_validator.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/security/presentation/backup_seed_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      final mainnetLocked = NetworkConfig.fromNetwork(HanbovaNetwork.mainnet);
      final mainnetPilot =
          NetworkConfig.fromNetwork(HanbovaNetwork.mainnet, pilotActive: true);

      // Verify storage prefix isolation
      expect(local.storagePrefix, 'wallet_local');
      expect(testnet.storagePrefix, 'wallet_cashu_test');
      expect(mainnetLocked.storagePrefix, 'wallet_mainnet');
      expect(mainnetPilot.storagePrefix, 'wallet_mainnet_pilot');

      // Verify all 4 prefixes are mutually distinct
      final prefixes = {
        local.storagePrefix,
        testnet.storagePrefix,
        mainnetLocked.storagePrefix,
        mainnetPilot.storagePrefix,
      };
      expect(prefixes.length, 4);

      // Verify Mainnet settings are locked for safety
      expect(mainnetLocked.isTestMode, isFalse);
      expect(mainnetLocked.isEnabled, isFalse);
      expect(mainnetLocked.displayName, contains('Locked'));
    });

    test(
        'Storage Isolation: CDK Redb paths are isolated between Testnut, Pilot, and Mainnet',
        () {
      const userId = 'user_alice_123';
      final testnetDir = CdkCashuWalletServiceImpl.computeDbDirName(
          userId, NetworkConfig.cashuTest.storagePrefix);
      final pilotDir = CdkCashuWalletServiceImpl.computeDbDirName(
          userId, NetworkConfig.mainnetPilot.storagePrefix);
      final mainnetDir = CdkCashuWalletServiceImpl.computeDbDirName(
          userId, NetworkConfig.mainnetLocked.storagePrefix);

      expect(testnetDir, 'hanbova_cdk_user_alice_123_wallet_cashu_test');
      expect(pilotDir, 'hanbova_cdk_user_alice_123_wallet_mainnet_pilot');
      expect(mainnetDir, 'hanbova_cdk_user_alice_123_wallet_mainnet');

      expect(testnetDir != pilotDir, isTrue);
      expect(pilotDir != mainnetDir, isTrue);
      expect(testnetDir != mainnetDir, isTrue);
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

    test('Total balance cap calculations enforce 10,000 sats limit fail-closed',
        () {
      final pilotConfig = NetworkConfig.mainnetPilot;
      expect(pilotConfig.maxWalletBalanceSats, 10000);

      // 1. 9,000 spendable + 1,001 deposit = 10,001 > 10,000 -> Rejected
      const balance1 =
          CashuWalletBalance(spendableSats: 9000, lockedEscrowSats: 0);
      expect(
          balance1.totalSats + 1001 > pilotConfig.maxWalletBalanceSats, isTrue);

      // 2. 7,000 spendable + 3,000 locked + 1 deposit = 10,001 > 10,000 -> Rejected
      const balance2 =
          CashuWalletBalance(spendableSats: 7000, lockedEscrowSats: 3000);
      expect(balance2.totalSats + 1 > pilotConfig.maxWalletBalanceSats, isTrue);

      // 3. 7,000 spendable + 3,000 locked + 0 deposit = 10,000 -> Allowed
      expect(
          balance2.totalSats + 0 <= pilotConfig.maxWalletBalanceSats, isTrue);

      // 4. 4,000 spendable + 1,000 locked + 5,000 deposit = 10,000 -> Allowed
      const balance3 =
          CashuWalletBalance(spendableSats: 4000, lockedEscrowSats: 1000);
      expect(balance3.totalSats + 5000 <= pilotConfig.maxWalletBalanceSats,
          isTrue);
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

    group('Strict MintValidator NUT Capability Verification', () {
      Map<String, dynamic> makeMintInfo({
        Map<String, dynamic>? nut04,
        Map<String, dynamic>? nut07,
        Map<String, dynamic>? nut10,
        Map<String, dynamic>? nut11,
      }) {
        return {
          'name': 'Test Mint',
          'description': 'Verification Test Mint',
          'nuts': {
            if (nut04 != null) '4': nut04,
            if (nut07 != null) '7': nut07,
            if (nut10 != null) '10': nut10,
            if (nut11 != null) '11': nut11,
          }
        };
      }

      final validNut04 = {
        'methods': [
          {'method': 'bolt11', 'unit': 'sat'}
        ]
      };
      final validNut07 = {'supported': true};
      final validNut10 = {'supported': true};
      final validNut11 = {'supported': true};

      test(
          'Complete valid mint with NUT-04 (bolt11/sat), 07, 10, 11 is fully supported',
          () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: validNut04,
                nut07: validNut07,
                nut10: validNut10,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.isValid, isTrue);
        expect(res.nut04Supported, isTrue);
        expect(res.nut07Supported, isTrue);
        expect(res.nut10Supported, isTrue);
        expect(res.nut11Supported, isTrue);
        expect(res.isFullySupported, isTrue);
      });

      test('Missing NUT-04 fails full support', () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut07: validNut07,
                nut10: validNut10,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut04Supported, isFalse);
        expect(res.isFullySupported, isFalse);
        expect(res.errorMessage, contains('NUT-04'));
      });

      test('Missing NUT-07 fails full support', () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: validNut04,
                nut10: validNut10,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut07Supported, isFalse);
        expect(res.isFullySupported, isFalse);
        expect(res.errorMessage, contains('NUT-07'));
      });

      test('Missing NUT-10 fails full support', () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: validNut04,
                nut07: validNut07,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut10Supported, isFalse);
        expect(res.isFullySupported, isFalse);
        expect(res.errorMessage, contains('NUT-10'));
      });

      test('Missing NUT-11 fails full support', () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: validNut04,
                nut07: validNut07,
                nut10: validNut10,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut11Supported, isFalse);
        expect(res.isFullySupported, isFalse);
        expect(res.errorMessage, contains('NUT-11'));
      });

      test('NUT-04 with only onchain method fails NUT-04 support', () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: {
                  'methods': [
                    {'method': 'onchain', 'unit': 'sat'}
                  ]
                },
                nut07: validNut07,
                nut10: validNut10,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut04Supported, isFalse);
        expect(res.isFullySupported, isFalse);
      });

      test('NUT-04 with bolt11 but non-sat unit fails NUT-04 support',
          () async {
        final client = MockClient((req) async {
          return http.Response(
              jsonEncode(makeMintInfo(
                nut04: {
                  'methods': [
                    {'method': 'bolt11', 'unit': 'usd'}
                  ]
                },
                nut07: validNut07,
                nut10: validNut10,
                nut11: validNut11,
              )),
              200);
        });

        final validator = MintValidator(client: client);
        final res = await validator.validateMint('https://mint.test');

        expect(res.nut04Supported, isFalse);
        expect(res.isFullySupported, isFalse);
      });
    });
  });
}
