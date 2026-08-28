import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../crypto/crypto_identity_service.dart';
import '../network/network_environment.dart';
import '../wallet/wallet_context.dart';
import 'cashu_wallet_models.dart';
import 'cashu_wallet_service.dart';
import 'cashu_wallet_storage.dart';

final cashuWalletStorageProvider = Provider<CashuWalletStorage>((ref) {
  return CashuWalletStorage();
});

final selectedMintUrlProvider = StateProvider<String?>((ref) => null);

typedef CashuWalletServiceFactory = CashuWalletService Function({
  required WalletContextKey context,
  required WalletCryptoIdentity identity,
  required String mintUrl,
  required CashuWalletStorage storage,
});

final cashuWalletServiceFactoryProvider =
    Provider<CashuWalletServiceFactory>((ref) {
  return ({
    required WalletContextKey context,
    required WalletCryptoIdentity identity,
    required String mintUrl,
    required CashuWalletStorage storage,
  }) {
    return CdkCashuWalletServiceImpl(
      userId: context.userId,
      network: context.network,
      walletSeedHex: identity.walletSeedHex,
      p2pkPrivateKeyHex: identity.protectedPaymentPrivkeyHex,
      p2pkPublicKeyHex: identity.protectedPaymentPubkey,
      storagePrefix: context.storagePrefix,
      mintUrl: mintUrl,
      storage: storage,
    );
  };
});

final cashuWalletServiceProvider = Provider<CashuWalletService?>((ref) {
  final context = ref.watch(activeWalletContextKeyProvider);
  final cryptoIdentity = ref.watch(cryptoIdentityProvider).valueOrNull;
  final config = ref.watch(activeNetworkConfigProvider);
  final selectedMint = ref.watch(selectedMintUrlProvider);
  final storage = ref.watch(cashuWalletStorageProvider);

  if (context == null ||
      cryptoIdentity == null ||
      cryptoIdentity.context != context ||
      !config.isEnabled ||
      config.network != context.network ||
      config.storagePrefix != context.storagePrefix) {
    return null;
  }

  // When Controlled Mainnet Pilot is active:
  // effective mint URL MUST ALWAYS equal config.defaultMintUrl (Minibits Bitcoin mint).
  // cashuWalletServiceProvider must ignore selectedMintUrlProvider in pilot mode.
  final effectiveMintUrl = config.isPilot
      ? config.defaultMintUrl
      : (selectedMint ?? config.defaultMintUrl);

  final service = ref.watch(cashuWalletServiceFactoryProvider)(
    context: context,
    identity: cryptoIdentity,
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
