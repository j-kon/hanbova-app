import '../../features/wallet/domain/asset_model.dart';

/// Normalized abstraction for future stablecoin wallet custody/infrastructure.
///
/// Hanbova's consumer UI strictly binds to normalized models, never directly
/// to specific providers like Bitnob or Flutterwave.
abstract class StablecoinWalletProvider {
  /// Unique identifier of the underlying provider (e.g. 'bitnob', 'flutterwave').
  String get providerId;

  /// Fetches normalized balance for a given stablecoin asset.
  Future<AssetBalance> getBalance(AssetType asset);

  /// Generates a deposit address for a stablecoin over a supported network.
  Future<String> getDepositAddress({
    required AssetType asset,
    required String network,
  });

  /// Lists supported settlement networks for an asset (e.g. TRC-20, ERC-20, Polygon).
  Future<List<String>> getSupportedNetworks(AssetType asset);
}

/// Normalized abstraction for asset-to-asset conversion quoting and execution.
abstract class AssetConversionProvider {
  /// Request a time-limited conversion quote between supported assets.
  Future<ConversionQuote> requestQuote({
    required ConversionPair pair,
    required double fromAmount,
  });

  /// Execute an accepted quote.
  ///
  /// Returns completed transaction reference or throws if execution fails or is uncertain.
  Future<String> executeConversion({required String quoteId});
}

/// Normalized abstraction for sending stablecoins to on-chain/network addresses.
abstract class StablecoinTransferProvider {
  /// Submits a transfer of stablecoin assets to an external destination.
  Future<String> initiateTransfer({
    required AssetType asset,
    required String destinationAddress,
    required String network,
    required double amount,
  });

  /// Estimates network transfer fees.
  Future<double> estimateTransferFee({
    required AssetType asset,
    required String network,
    required double amount,
  });
}

/// Normalized abstraction for fiat-to-asset and asset-to-fiat quoting.
abstract class FiatConversionProvider {
  /// Estimates conversion between local fiat currency and BTC/stablecoins.
  Future<double> getFiatRate({
    required String fiatCurrency,
    required AssetType asset,
  });
}
