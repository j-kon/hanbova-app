import 'package:flutter/material.dart';

/// Supported global wallet asset types in Hanbova.
enum AssetType {
  btc,
  usdt,
  usdc;

  String get symbol {
    switch (this) {
      case AssetType.btc:
        return 'BTC';
      case AssetType.usdt:
        return 'USDT';
      case AssetType.usdc:
        return 'USDC';
    }
  }

  String get name {
    switch (this) {
      case AssetType.btc:
        return 'Bitcoin';
      case AssetType.usdt:
        return 'Tether USD';
      case AssetType.usdc:
        return 'USD Coin';
    }
  }

  String get ticker {
    switch (this) {
      case AssetType.btc:
        return 'BTC';
      case AssetType.usdt:
        return 'USDT';
      case AssetType.usdc:
        return 'USDC';
    }
  }

  bool get isBitcoin => this == AssetType.btc;
  bool get isStablecoin => this == AssetType.usdt || this == AssetType.usdc;

  int get decimals {
    switch (this) {
      case AssetType.btc:
        return 8;
      case AssetType.usdt:
      case AssetType.usdc:
        return 2;
    }
  }

  Color get color {
    switch (this) {
      case AssetType.btc:
        return const Color(0xFFF7931A);
      case AssetType.usdt:
        return const Color(0xFF26A17B);
      case AssetType.usdc:
        return const Color(0xFF2775CA);
    }
  }

  IconData get icon {
    switch (this) {
      case AssetType.btc:
        return Icons.currency_bitcoin_rounded;
      case AssetType.usdt:
        return Icons.attach_money_rounded;
      case AssetType.usdc:
        return Icons.monetization_on_rounded;
    }
  }
}

/// Normalized lifecycle and availability state for an asset.
enum AssetFeatureState {
  unavailable,
  comingSoon,
  setupRequired,
  verificationRequired,
  active,
  restricted;

  String get label {
    switch (this) {
      case AssetFeatureState.unavailable:
        return 'Unavailable';
      case AssetFeatureState.comingSoon:
        return 'Coming Soon';
      case AssetFeatureState.setupRequired:
        return 'Setup Required';
      case AssetFeatureState.verificationRequired:
        return 'Verification Required';
      case AssetFeatureState.active:
        return 'Active';
      case AssetFeatureState.restricted:
        return 'Restricted';
    }
  }

  Color get color {
    switch (this) {
      case AssetFeatureState.active:
        return const Color(0xFF10B981);
      case AssetFeatureState.comingSoon:
        return const Color(0xFF38BDF8);
      case AssetFeatureState.setupRequired:
        return const Color(0xFFF59E0B);
      case AssetFeatureState.verificationRequired:
        return const Color(0xFFA855F7);
      case AssetFeatureState.restricted:
      case AssetFeatureState.unavailable:
        return const Color(0xFFEF4444);
    }
  }
}

/// Normalized multi-asset balance representation.
class AssetBalance {
  final AssetType asset;
  final double total;
  final double available;
  final double pending;
  final int satsAmount;
  final AssetFeatureState featureState;
  final bool isDemo;

  const AssetBalance({
    required this.asset,
    required this.total,
    required this.available,
    this.pending = 0.0,
    this.satsAmount = 0,
    required this.featureState,
    this.isDemo = false,
  });

  String get formattedBalance {
    if (asset == AssetType.btc) {
      return '$satsAmount sats';
    }
    return '\$${total.toStringAsFixed(2)}';
  }

  String get formattedAvailable {
    if (asset == AssetType.btc) {
      return '$satsAmount sats available';
    }
    return '\$${available.toStringAsFixed(2)} available';
  }
}

/// Supported conversion pairs in Hanbova.
class ConversionPair {
  final AssetType from;
  final AssetType to;

  const ConversionPair({required this.from, required this.to});

  String get label => '${from.symbol} → ${to.symbol}';

  bool get isInverseOfSelf => from == to;

  static const List<ConversionPair> supportedPairs = [
    ConversionPair(from: AssetType.btc, to: AssetType.usdt),
    ConversionPair(from: AssetType.btc, to: AssetType.usdc),
    ConversionPair(from: AssetType.usdt, to: AssetType.btc),
    ConversionPair(from: AssetType.usdc, to: AssetType.btc),
    ConversionPair(from: AssetType.usdt, to: AssetType.usdc),
    ConversionPair(from: AssetType.usdc, to: AssetType.usdt),
  ];
}

/// Conversion quote model.
class ConversionQuote {
  final String id;
  final ConversionPair pair;
  final double fromAmount;
  final double toAmount;
  final double exchangeRate;
  final double feeAmount;
  final String feeAsset;
  final DateTime expiresAt;
  final bool isSampleQuote;

  const ConversionQuote({
    required this.id,
    required this.pair,
    required this.fromAmount,
    required this.toAmount,
    required this.exchangeRate,
    required this.feeAmount,
    required this.feeAsset,
    required this.expiresAt,
    this.isSampleQuote = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get secondsRemaining {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// Conversion lifecycle state machine.
enum ConversionLifecycleStatus {
  quoteLoading,
  quoted,
  quoteExpired,
  confirming,
  processing,
  completed,
  failed,
  uncertain;

  String get displayLabel {
    switch (this) {
      case ConversionLifecycleStatus.quoteLoading:
        return 'Fetching Quote...';
      case ConversionLifecycleStatus.quoted:
        return 'Quote Ready';
      case ConversionLifecycleStatus.quoteExpired:
        return 'Quote Expired';
      case ConversionLifecycleStatus.confirming:
        return 'Confirming Conversion...';
      case ConversionLifecycleStatus.processing:
        return 'Processing Swap...';
      case ConversionLifecycleStatus.completed:
        return 'Conversion Completed';
      case ConversionLifecycleStatus.failed:
        return 'Conversion Failed';
      case ConversionLifecycleStatus.uncertain:
        return 'Conversion Processing (Uncertain Outcome)';
    }
  }
}
