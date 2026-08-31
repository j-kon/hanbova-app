class ConsumerErrorTranslator {
  static String translate(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    String raw = error.toString().trim();

    // Strip exception wrapper prefixes
    raw = raw
        .replaceAll(
            RegExp(
                r'^(Bad state:\s*|Exception:\s*|StateError:\s*|FormatException:\s*)'),
            '')
        .replaceAll(
            RegExp(
                r'^(ClientException:\s*|SocketException:\s*|HandshakeException:\s*)'),
            '')
        .trim();

    final originalLower = error.toString().toLowerCase();
    final lower = raw.toLowerCase();

    // 1. Network / Connectivity
    if (originalLower.contains('socketexception') ||
        originalLower.contains('handshakeexception') ||
        originalLower.contains('failed host lookup') ||
        originalLower.contains('host lookup') ||
        lower.contains('failed to connect') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('timed out') ||
        lower.contains('timeout')) {
      return 'Network connection unavailable. Please check your connection and try again.';
    }

    // 2. Cashu Mint Failures
    if (lower.contains('mint') &&
        (lower.contains('unreachable') ||
            lower.contains('502') ||
            lower.contains('503') ||
            lower.contains('unavailable'))) {
      return 'Mint unreachable. Please try again in a few moments.';
    }

    // 3. Proofs already spent / claimed / race conditions
    if (lower.contains('already spent') ||
        lower.contains('token already spent') ||
        lower.contains('proofs already spent') ||
        lower.contains('inputs already spent')) {
      return 'Payment has already been claimed or refunded.';
    }

    // 4. Locktime not expired
    if (lower.contains('locktime') ||
        lower.contains('not yet claimable') ||
        lower.contains('refund unavailable')) {
      return 'Refund not available yet. The protection locktime has not expired.';
    }

    // 5. Identity / Key mismatches
    if (lower.contains('fingerprint') ||
        lower.contains('key mismatch') ||
        lower.contains('invalid pubkey')) {
      return 'Recipient wallet identity changed. Please verify recipient handle.';
    }

    // 6. Balance / Insufficient funds
    if (lower.contains('insufficient') ||
        lower.contains('not enough balance')) {
      return 'Insufficient spendable balance for this payment.';
    }

    // 7. Delivery / Relay failures
    if (lower.contains('delivery') || lower.contains('relay')) {
      return 'Payment locked in wallet. Delivery pending — tap Retry Delivery.';
    }

    // 8. Auth / Session failures
    if (lower.contains('unauthorized') ||
        lower.contains('401') ||
        lower.contains('jwt') ||
        lower.contains('session expired')) {
      return 'Session expired. Please sign in again.';
    }

    // 9. Forbidden
    if (lower.contains('forbidden') || lower.contains('403')) {
      return 'Action not permitted for this account.';
    }

    // Safety sanitize: redact hex sequences >= 32 chars or paths
    String sanitized =
        raw.replaceAll(RegExp(r'[0-9a-fA-F]{32,}'), '[redacted]');
    sanitized = sanitized.replaceAll(RegExp(r'/Users/[^\s]+'), '[local path]');
    sanitized = sanitized.replaceAll(RegExp(r'/data/[^\s]+'), '[local path]');

    if (sanitized.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Capitalize first letter
    return '${sanitized[0].toUpperCase()}${sanitized.substring(1)}';
  }
}
