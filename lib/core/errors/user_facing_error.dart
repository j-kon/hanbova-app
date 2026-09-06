import 'dart:async';
import 'dart:io';

import '../cashu/wallet_policy.dart';
import 'app_failure.dart';

enum UserErrorCode {
  authenticationRequired,
  walletUnavailable,
  offline,
  invalidPayment,
  policyLimit,
  insufficientBalance,
  quoteExpired,
  quoteUnpaid,
  recipientUnavailable,
  coordinationPending,
  unexpected,
}

final class UserFacingError {
  final UserErrorCode code;
  final String message;
  final bool retryable;

  const UserFacingError(
    this.code,
    this.message, {
    this.retryable = false,
  });
}

abstract final class UserFacingErrorMapper {
  static UserFacingError from(Object? error) {
    if (error is WalletPolicyViolation) {
      return const UserFacingError(
        UserErrorCode.policyLimit,
        'This amount exceeds the wallet safety limit.',
      );
    }
    if (error is AppFailure) {
      final mapped = _fromCode(error.code);
      if (mapped != null) return mapped;
      final original = error.originalError;
      if (original is SocketException) return _offline;
      if (original is TimeoutException) return _timeout;
    }
    if (error is SocketException) return _offline;
    if (error is TimeoutException) return _timeout;

    final value = error?.toString().toLowerCase() ?? '';
    if (_containsAny(value, const [
      'socketexception',
      'handshakeexception',
      'failed host lookup',
      'connection refused',
      'network is unreachable',
    ])) {
      return _offline;
    }
    if (_containsAny(value, const ['timeout', 'timed out'])) return _timeout;
    if (value.contains('user must be authenticated')) {
      return const UserFacingError(
        UserErrorCode.authenticationRequired,
        'User must be authenticated to continue.',
      );
    }
    if (_containsAny(value, const [
      'authentication_required',
      'unauthorized',
      'session expired',
    ])) {
      return _authentication;
    }
    if (_containsAny(value, const [
      'wallet is not initialized',
      'wallet not initialized',
      'wallet unavailable',
      'wallet context is required',
    ])) {
      return const UserFacingError(
        UserErrorCode.walletUnavailable,
        'Cashu wallet is not initialized. Sign in again and retry.',
        retryable: true,
      );
    }
    if (_containsAny(value, const [
      'insufficient',
      'not enough balance',
    ])) {
      return const UserFacingError(
        UserErrorCode.insufficientBalance,
        'Insufficient spendable balance for this payment.',
      );
    }
    if (_containsAny(
        value, const ['could not be found', 'recipient unavailable'])) {
      return const UserFacingError(
        UserErrorCode.recipientUnavailable,
        'Recipient could not be found for the active wallet network.',
        retryable: true,
      );
    }
    if (_containsAny(value, const ['delivery', 'relay'])) {
      return const UserFacingError(
        UserErrorCode.coordinationPending,
        'Payment locked in wallet. Delivery pending — tap Retry Delivery.',
        retryable: true,
      );
    }
    if (_containsAny(value, const [
      'remains bound to',
      'previous recipient key',
    ])) {
      return const UserFacingError(
        UserErrorCode.recipientUnavailable,
        'Recipient wallet identity changed. This protected payment remains bound to the previous recipient key. Wait for Refund availability, then create a new payment.',
      );
    }
    if (_containsAny(
        value, const ['fingerprint', 'key mismatch', 'invalid pubkey'])) {
      return const UserFacingError(
        UserErrorCode.recipientUnavailable,
        'Recipient wallet identity changed. Please verify the recipient handle.',
      );
    }
    if (value.contains('failed to encrypt transport envelope')) {
      return const UserFacingError(
        UserErrorCode.coordinationPending,
        'Failed to encrypt transport envelope. Your locked payment remains recoverable.',
        retryable: true,
      );
    }
    if (_containsAny(value, const ['quote expired', 'invoice has expired'])) {
      return const UserFacingError(
        UserErrorCode.quoteExpired,
        'This payment quote has expired. Create a new one.',
      );
    }
    if (_containsAny(
        value, const ['quote unpaid', 'invoice is still unpaid'])) {
      return const UserFacingError(
        UserErrorCode.quoteUnpaid,
        'This invoice is still unpaid.',
        retryable: true,
      );
    }
    if (_containsAny(value, const [
      'different bitcoin network',
      'invalid lightning',
      'valid lightning invoice',
      'amountless lightning',
    ])) {
      return const UserFacingError(
        UserErrorCode.invalidPayment,
        'Enter a valid Lightning invoice for the active network.',
      );
    }
    if (_containsAny(value, const ['locktime', 'refund unavailable'])) {
      return const UserFacingError(
        UserErrorCode.invalidPayment,
        'Refund is not available until the protection window ends.',
      );
    }
    if (_containsAny(value, const ['already spent', 'inputs already spent'])) {
      return const UserFacingError(
        UserErrorCode.invalidPayment,
        'This payment has already been claimed or refunded.',
      );
    }
    return const UserFacingError(
      UserErrorCode.unexpected,
      'Something went wrong. Your wallet state was not discarded.',
    );
  }

  static UserFacingError? _fromCode(String? rawCode) {
    final code = rawCode?.trim().toLowerCase();
    return switch (code) {
      '401' ||
      'unauthorized' ||
      'authentication_required' ||
      'session_expired' =>
        _authentication,
      'authentication_denied' => const UserFacingError(
          UserErrorCode.authenticationRequired,
          'Authentication was not completed.',
          retryable: true,
        ),
      'network_error' || 'offline' || 'connection_failed' => _offline,
      'timeout' || 'request_timeout' => _timeout,
      'send_limit' ||
      'deposit_limit' ||
      'wallet_limit' ||
      'invalid_amount' =>
        const UserFacingError(
          UserErrorCode.policyLimit,
          'This amount exceeds the wallet safety limit.',
        ),
      'insufficient_balance' => const UserFacingError(
          UserErrorCode.insufficientBalance,
          'Insufficient spendable balance for this payment.',
        ),
      'quote_expired' => const UserFacingError(
          UserErrorCode.quoteExpired,
          'This payment quote has expired. Create a new one.',
        ),
      'quote_unpaid' => const UserFacingError(
          UserErrorCode.quoteUnpaid,
          'This invoice is still unpaid.',
          retryable: true,
        ),
      'recipient_not_found' || '404' => const UserFacingError(
          UserErrorCode.recipientUnavailable,
          'Recipient could not be found for the active wallet network.',
          retryable: true,
        ),
      'wallet_unavailable' || 'wallet_rebuild_failed' => const UserFacingError(
          UserErrorCode.walletUnavailable,
          'Wallet unavailable. Sign in again and retry.',
          retryable: true,
        ),
      'session_changed' => const UserFacingError(
          UserErrorCode.walletUnavailable,
          'Your account or wallet environment changed. Start restore again.',
          retryable: true,
        ),
      'identity_restore_failed' ||
      'backup_confirmation_failed' =>
        const UserFacingError(
          UserErrorCode.walletUnavailable,
          'The wallet identity could not be restored safely on this device.',
          retryable: true,
        ),
      'invalid_phrase' => const UserFacingError(
          UserErrorCode.invalidPayment,
          'The recovery phrase is invalid. Check every word and try again.',
        ),
      _ => null,
    };
  }

  static bool _containsAny(String value, List<String> candidates) =>
      candidates.any(value.contains);

  static const _authentication = UserFacingError(
    UserErrorCode.authenticationRequired,
    'Your session has expired. Sign in again to continue.',
  );
  static const _offline = UserFacingError(
    UserErrorCode.offline,
    'You appear to be offline. Check your connection and try again.',
    retryable: true,
  );
  static const _timeout = UserFacingError(
    UserErrorCode.offline,
    'The request timed out. Check your connection and try again.',
    retryable: true,
  );
}
