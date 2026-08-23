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

  const NetworkConfig({
    required this.network,
    required this.displayName,
    required this.description,
    required this.defaultMintUrl,
    required this.isTestMode,
    required this.isEnabled,
    required this.storagePrefix,
  });

  static const local = NetworkConfig(
    network: HanbovaNetwork.local,
    displayName: 'Local Development',
    description: 'Local Nutshell / FakeWallet for testing',
    defaultMintUrl: 'http://127.0.0.1:3338',
    isTestMode: true,
    isEnabled: true,
    storagePrefix: 'wallet_local',
  );

  static const cashuTest = NetworkConfig(
    network: HanbovaNetwork.cashuTest,
    displayName: 'Cashu Test',
    description: 'Public test mint (No monetary value)',
    defaultMintUrl: 'https://testnut.cashu.space',
    isTestMode: true,
    isEnabled: true,
    storagePrefix: 'wallet_cashu_test',
  );

  static const mainnet = NetworkConfig(
    network: HanbovaNetwork.mainnet,
    displayName: 'Mainnet',
    description: 'Unavailable during testing',
    defaultMintUrl: '',
    isTestMode: false,
    isEnabled: false,
    storagePrefix: 'wallet_mainnet',
  );

  static NetworkConfig fromNetwork(HanbovaNetwork net) {
    switch (net) {
      case HanbovaNetwork.local:
        return local;
      case HanbovaNetwork.cashuTest:
        return cashuTest;
      case HanbovaNetwork.mainnet:
        return mainnet;
    }
  }
}

final networkEnvironmentProvider =
    StateNotifierProvider<NetworkEnvironmentNotifier, HanbovaNetwork>((ref) {
  return NetworkEnvironmentNotifier();
});

class NetworkEnvironmentNotifier extends StateNotifier<HanbovaNetwork> {
  static const _storageKey = 'hanbova_network_environment';
  final FlutterSecureStorage _storage;

  NetworkEnvironmentNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(HanbovaNetwork.local) {
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
          case 'local':
          default:
            state = HanbovaNetwork.local;
            break;
        }
      }
    } catch (_) {}
  }

  Future<void> setNetwork(HanbovaNetwork net) async {
    if (net == HanbovaNetwork.mainnet) {
      throw UnsupportedError('Mainnet is disabled in this build of Hanbova');
    }
    state = net;
    try {
      await _storage.write(key: _storageKey, value: net.name);
    } catch (_) {}
  }
}
