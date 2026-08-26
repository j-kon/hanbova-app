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

final selectedMintUrlProvider = StateProvider<String?>((ref) => null);

final cashuWalletServiceProvider = Provider<CashuWalletService?>((ref) {
  final authState = ref.watch(authProvider);
  final cryptoIdentity = ref.watch(cryptoIdentityProvider).value;
  final config = ref.watch(activeNetworkConfigProvider);
  final selectedMint = ref.watch(selectedMintUrlProvider);
  final storage = ref.watch(cashuWalletStorageProvider);

  if (authState.user == null || cryptoIdentity == null) {
    return null;
  }

  // When Controlled Mainnet Pilot is active:
  // effective mint URL MUST ALWAYS equal config.defaultMintUrl (Minibits Bitcoin mint).
  // cashuWalletServiceProvider must ignore selectedMintUrlProvider in pilot mode.
  final effectiveMintUrl = config.isPilot
      ? config.defaultMintUrl
      : (selectedMint ?? config.defaultMintUrl);

  final service = CdkCashuWalletServiceImpl(
    userId: authState.user!.id,
    network: config.network,
    walletSeedHex: cryptoIdentity.walletSeedHex,
    p2pkPrivateKeyHex: cryptoIdentity.protectedPaymentPrivkeyHex,
    p2pkPublicKeyHex: cryptoIdentity.protectedPaymentPubkey,
    mintUrl: effectiveMintUrl,
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
