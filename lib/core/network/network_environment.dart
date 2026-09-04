import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    this.maxWalletBalanceSats = 1000000,
    this.maxDepositSats = 1000000,
    this.maxSendSats = 1000000,
  });

  /// Compile-time pilot build flag
  static const bool isMainnetPilotBuild =
      bool.fromEnvironment('MAINNET_DEMO_PILOT', defaultValue: false);

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
  return NetworkEnvironmentNotifier();
});

/// Centralized active network configuration. Mainnet availability is fixed at
/// compile time and cannot be changed by runtime provider state.
final activeNetworkConfigProvider = Provider<NetworkConfig>((ref) {
  final net = ref.watch(networkEnvironmentProvider);
  return NetworkConfig.fromNetwork(net);
});

class NetworkEnvironmentNotifier extends StateNotifier<HanbovaNetwork> {
  static const _storageKey = 'hanbova_network_environment';
  final FlutterSecureStorage _storage;

  NetworkEnvironmentNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(NetworkConfig.isMainnetPilotBuild
            ? HanbovaNetwork.mainnet
            : HanbovaNetwork.local) {
    _loadNetwork();
  }

  Future<void> _loadNetwork() async {
    try {
      final saved = await _storage.read(key: _storageKey);
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
