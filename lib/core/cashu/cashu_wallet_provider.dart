import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../crypto/crypto_identity_service.dart';
import '../network/network_environment.dart';
import 'cashu_wallet_models.dart';
import 'cashu_wallet_service.dart';
import 'cashu_wallet_storage.dart';

final cashuWalletStorageProvider = Provider<CashuWalletStorage>((ref) {
  return CashuWalletStorage();
});

final cashuWalletServiceProvider = Provider<CashuWalletService?>((ref) {
  final authState = ref.watch(authProvider);
  final cryptoIdentity = ref.watch(cryptoIdentityProvider).value;
  final network = ref.watch(networkEnvironmentProvider);
  final storage = ref.watch(cashuWalletStorageProvider);

  if (authState.user == null || cryptoIdentity == null) {
    return null;
  }

  final service = CdkCashuWalletServiceImpl(
    userId: authState.user!.id,
    network: network,
    walletSeedHex: cryptoIdentity.walletSeedHex,
    p2pkPrivateKeyHex: cryptoIdentity.protectedPaymentPrivkeyHex,
    p2pkPublicKeyHex: cryptoIdentity.protectedPaymentPubkey,
    storage: storage,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

final cashuBalanceProvider = FutureProvider<CashuWalletBalance>((ref) async {
  final walletService = ref.watch(cashuWalletServiceProvider);
  if (walletService == null) {
    return const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
  }
  return await walletService.getBalance();
});
