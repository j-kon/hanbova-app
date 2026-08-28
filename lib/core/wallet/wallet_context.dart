import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../network/network_environment.dart';

@immutable
final class WalletContextKey {
  final String userId;
  final HanbovaNetwork network;
  final String storagePrefix;

  const WalletContextKey({
    required this.userId,
    required this.network,
    required this.storagePrefix,
  });

  static WalletContextKey? fromSession(
    AuthState auth,
    NetworkConfig config,
  ) {
    final userId = auth.user?.id.trim() ?? '';
    if (!auth.isAuthenticated || userId.isEmpty || !config.isEnabled) {
      return null;
    }

    return WalletContextKey(
      userId: userId,
      network: config.network,
      storagePrefix: config.storagePrefix,
    );
  }

  static String _encode(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  String get storageId =>
      'v1_${network.name}_${_encode(storagePrefix)}_${_encode(userId)}';

  String get identityStoragePrefix => 'hanbova_wallet_$storageId';

  String get legacyIdentityStoragePrefix => 'hanbova_${storagePrefix}_$userId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletContextKey &&
          other.userId == userId &&
          other.network == network &&
          other.storagePrefix == storagePrefix;

  @override
  int get hashCode => Object.hash(userId, network, storagePrefix);
}

final activeWalletContextKeyProvider = Provider<WalletContextKey?>((ref) {
  return WalletContextKey.fromSession(
    ref.watch(authProvider),
    ref.watch(activeNetworkConfigProvider),
  );
});
