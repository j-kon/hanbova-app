import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/wallet_backup_store.dart';
import '../../../core/wallet/wallet_context.dart';

enum RestoreWalletOutcome { restored, syncPending }

final class RestoreWalletResult {
  final RestoreWalletOutcome outcome;
  final WalletCryptoIdentity identity;

  const RestoreWalletResult(this.outcome, this.identity);
}

final class RestoreWalletFailure implements Exception {
  final String code;
  final String message;

  const RestoreWalletFailure(this.code, this.message);

  @override
  String toString() => message;
}

final restoreWalletControllerProvider =
    Provider<RestoreWalletController>((ref) {
  return RestoreWalletController(ref);
});

class RestoreWalletController {
  final Ref ref;

  const RestoreWalletController(this.ref);

  static const _sessionChanged = RestoreWalletFailure(
    'session_changed',
    'Your account or wallet environment changed. Start restore again.',
  );

  bool _isCurrent(WalletContextKey context) =>
      ref.read(activeWalletContextKeyProvider) == context;

  Future<RestoreWalletResult> restore(String mnemonic) async {
    final context = ref.read(activeWalletContextKeyProvider);
    if (context == null) {
      throw const RestoreWalletFailure(
        'authentication_required',
        'Sign in to restore your wallet.',
      );
    }

    final authorized = await ref.read(biometricServiceProvider).authenticate(
          reason: 'Authenticate to replace this wallet identity',
        );
    if (!authorized) {
      throw const RestoreWalletFailure(
        'authentication_denied',
        'Authentication was not completed.',
      );
    }
    if (!_isCurrent(context)) throw _sessionChanged;

    final WalletCryptoIdentity identity;
    try {
      identity = await ref
          .read(cryptoIdentityProvider.notifier)
          .restoreFromMnemonic(mnemonic: mnemonic);
    } on StaleWalletContextException {
      throw _sessionChanged;
    } on WalletContextUnavailableException {
      throw _sessionChanged;
    } on ArgumentError {
      throw const RestoreWalletFailure(
        'invalid_phrase',
        'The recovery phrase is invalid. Check every word and try again.',
      );
    } catch (_) {
      throw const RestoreWalletFailure(
        'identity_restore_failed',
        'The wallet identity could not be restored on this device.',
      );
    }

    if (!_isCurrent(context) || identity.context != context) {
      throw _sessionChanged;
    }

    var outcome = RestoreWalletOutcome.restored;
    try {
      await ref.read(cryptoIdentityProvider.notifier).publishPublicKeys(
            apiClient: ref.read(apiClientProvider),
            identity: identity,
          );
    } catch (_) {
      outcome = RestoreWalletOutcome.syncPending;
    }
    if (!_isCurrent(context)) throw _sessionChanged;

    final wallet = ref.read(cashuWalletServiceProvider);
    if (wallet == null) {
      throw const RestoreWalletFailure(
        'wallet_unavailable',
        'The wallet identity was saved, but the wallet could not be opened.',
      );
    }
    try {
      final _ = await ref.refresh(cashuBalanceProvider.future);
    } catch (_) {
      throw const RestoreWalletFailure(
        'wallet_rebuild_failed',
        'The wallet identity was saved, but the wallet could not be rebuilt.',
      );
    }
    if (!_isCurrent(context)) throw _sessionChanged;

    try {
      await ref.read(walletBackupStatusProvider.notifier).confirm();
    } on StaleWalletContextException {
      throw _sessionChanged;
    } catch (_) {
      throw const RestoreWalletFailure(
        'backup_confirmation_failed',
        'The wallet identity was saved, but backup confirmation could not be stored.',
      );
    }
    if (!_isCurrent(context)) throw _sessionChanged;

    return RestoreWalletResult(outcome, identity);
  }

  Future<bool> retryPublicKeySync() async {
    final context = ref.read(activeWalletContextKeyProvider);
    if (context == null) return false;

    try {
      final identity =
          await ref.read(cryptoIdentityProvider.notifier).requireIdentity();
      if (!_isCurrent(context) || identity.context != context) return false;
      await ref.read(cryptoIdentityProvider.notifier).publishPublicKeys(
            apiClient: ref.read(apiClientProvider),
            identity: identity,
          );
      return _isCurrent(context);
    } catch (_) {
      return false;
    }
  }
}
