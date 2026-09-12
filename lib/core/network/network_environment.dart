import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/digests/sha256.dart';

import '../config/app_config.dart';
import '../networking/api_client.dart';

enum HanbovaNetwork {
  local,
  cashuTest,
  mainnet,
}

class NetworkConfig {
  final HanbovaNetwork network;
  final String displayName;
  final String description;
  final String defaultMintUrl;
  final bool isTestMode;
  final bool isEnabled;
  final String storagePrefix;
  final bool isPilot;
  final bool lockMintSelection;
  final int maxWalletBalanceSats;
  final int maxDepositSats;
  final int maxSendSats;

  const NetworkConfig({
    required this.network,
    required this.displayName,
    required this.description,
    required this.defaultMintUrl,
    required this.isTestMode,
    required this.isEnabled,
    required this.storagePrefix,
    this.isPilot = false,
    this.lockMintSelection = false,
    this.maxWalletBalanceSats = 1000000,
    this.maxDepositSats = 1000000,
    this.maxSendSats = 1000000,
  });

  /// Compile-time pilot build flag
  static const bool isMainnetPilotBuild =
      bool.fromEnvironment('MAINNET_DEMO_PILOT', defaultValue: false) &&
          String.fromEnvironment('HANBOVA_ENV') != 'pilot' &&
          String.fromEnvironment('HANBOVA_ENV') != 'production';

  static NetworkConfig privatePilot(AppConfig config) {
    final endpointId = base64Url
        .encode(SHA256Digest().process(
          utf8.encode(jsonEncode([config.apiBaseUrl, config.mintUrl])),
        ))
        .replaceAll('=', '');
    return NetworkConfig(
      network: HanbovaNetwork.cashuTest,
      displayName: 'Private Pilot • Test Mode',
      description: 'Configured private test mint (No monetary value)',
      defaultMintUrl: config.mintUrl,
      isTestMode: true,
      isEnabled: true,
      // Sent as wallet_environment to the API's VARCHAR(50) columns.
      storagePrefix: 'pilot_$endpointId',
      lockMintSelection: true,
      maxWalletBalanceSats: cashuTest.maxWalletBalanceSats,
      maxDepositSats: cashuTest.maxDepositSats,
      maxSendSats: cashuTest.maxSendSats,
    );
  }

  static const local = NetworkConfig(
    network: HanbovaNetwork.local,
    displayName: 'Local Development',
    description: 'Local Nutshell / FakeWallet for testing',
    defaultMintUrl: 'http://127.0.0.1:3338',
    isTestMode: true,
    isEnabled: true,
    storagePrefix: 'wallet_local',
    maxWalletBalanceSats: 500000,
    maxDepositSats: 500000,
    maxSendSats: 500000,
  );

  static const cashuTest = NetworkConfig(
    network: HanbovaNetwork.cashuTest,
    displayName: 'Cashu Test',
    description: 'Public test mint (No monetary value)',
    defaultMintUrl: 'https://testnut.cashu.space',
    isTestMode: true,
    isEnabled: true,
    storagePrefix: 'wallet_cashu_test',
    maxWalletBalanceSats: 100000,
    maxDepositSats: 100000,
    maxSendSats: 100000,
  );

  static const mainnetLocked = NetworkConfig(
    network: HanbovaNetwork.mainnet,
    displayName: 'Bitcoin Mainnet (Locked)',
    description: 'Disabled in standard builds (Safety Lock)',
    defaultMintUrl: 'https://mint.minibits.cash/Bitcoin',
    isTestMode: false,
    isEnabled: false,
    storagePrefix: 'wallet_mainnet',
    maxWalletBalanceSats: 0,
    maxDepositSats: 0,
    maxSendSats: 0,
  );

  static const mainnet = mainnetLocked;

  static const mainnetPilot = NetworkConfig(
    network: HanbovaNetwork.mainnet,
    displayName: 'Bitcoin Mainnet (Pilot)',
    description: 'Controlled Pilot • Max 10,000 sats wallet / 5,000 sats send',
    defaultMintUrl: 'https://mint.minibits.cash/Bitcoin',
    isTestMode: false,
    isEnabled: true,
    storagePrefix: 'wallet_mainnet_pilot',
    isPilot: true,
    maxWalletBalanceSats: 10000, // Strict pilot limit in sats
    maxDepositSats: 10000, // Strict pilot limit in sats
    maxSendSats: 5000, // Strict pilot limit in sats
  );

  static NetworkConfig fromNetwork(HanbovaNetwork net) {
    switch (net) {
      case HanbovaNetwork.local:
        return local;
      case HanbovaNetwork.cashuTest:
        return cashuTest;
      case HanbovaNetwork.mainnet:
        return isMainnetPilotBuild ? mainnetPilot : mainnetLocked;
    }
  }
}

final networkEnvironmentProvider =
    StateNotifierProvider<NetworkEnvironmentNotifier, HanbovaNetwork>((ref) {
  return NetworkEnvironmentNotifier(config: ref.watch(appConfigProvider));
});

/// Centralized active network configuration. Mainnet availability is fixed at
/// compile time and cannot be changed by runtime provider state.
final activeNetworkConfigProvider = Provider<NetworkConfig>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  if (appConfig.isPilot) return NetworkConfig.privatePilot(appConfig);
  final net = ref.watch(networkEnvironmentProvider);
  return NetworkConfig.fromNetwork(net);
});

class NetworkEnvironmentNotifier extends StateNotifier<HanbovaNetwork> {
  static const _storageKey = 'hanbova_network_environment';
  final FlutterSecureStorage _storage;
  final bool _privatePilot;

  NetworkEnvironmentNotifier({FlutterSecureStorage? storage, AppConfig? config})
      : _storage = storage ?? const FlutterSecureStorage(),
        _privatePilot = config?.isPilot ?? false,
        super(config?.isPilot == true
            ? HanbovaNetwork.cashuTest
            : NetworkConfig.isMainnetPilotBuild
                ? HanbovaNetwork.mainnet
                : HanbovaNetwork.local) {
    if (!_privatePilot) _loadNetwork();
  }

  Future<void> _loadNetwork() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (!mounted) return;
      if (saved != null) {
        switch (saved) {
          case 'cashuTest':
            state = HanbovaNetwork.cashuTest;
            break;
          case 'mainnet':
            if (NetworkConfig.isMainnetPilotBuild) {
              state = HanbovaNetwork.mainnet;
            } else {
              state = HanbovaNetwork.local;
            }
            break;
          case 'local':
          default:
            state = NetworkConfig.isMainnetPilotBuild
                ? HanbovaNetwork.mainnet
                : HanbovaNetwork.local;
            break;
        }
      } else if (NetworkConfig.isMainnetPilotBuild) {
        state = HanbovaNetwork.mainnet;
      }
    } catch (_) {}
  }

  Future<void> setNetwork(HanbovaNetwork net) async {
    if (_privatePilot || !mounted) return;
    final config = NetworkConfig.fromNetwork(net);
    if (!config.isEnabled) {
      // Mainnet is locked
      return;
    }
    state = net;
    try {
      await _storage.write(key: _storageKey, value: net.name);
    } catch (_) {}
  }
}
