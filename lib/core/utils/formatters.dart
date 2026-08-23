import 'package:intl/intl.dart';

class Formatters {
  static final _numberFormat = NumberFormat('#,##0', 'en_US');

  /// Formats satoshi amounts cleanly with commas (e.g. 100,000 sats).
  static String formatSats(int sats) {
    return '${_numberFormat.format(sats)} sats';
  }

  /// Estimated USD equivalent (mock conversion rate for UI).
  static String satsToUsd(int sats, {double btcUsdRate = 95000.0}) {
    final btc = sats / 100000000.0;
    final usd = btc * btcUsdRate;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(usd);
  }

  /// Formats relative time / countdown for expiration.
  static String formatExpiresIn(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inHours > 24) {
      return '${difference.inDays}d ${difference.inHours % 24}h remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m remaining';
    } else {
      return '${difference.inSeconds}s remaining';
    }
  }

  /// Formats date for transaction timestamps.
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y • HH:mm').format(date);
  }
}
