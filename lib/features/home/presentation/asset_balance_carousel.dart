import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/security/privacy_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../wallet/domain/asset_model.dart';

/// Supported assets displayed in the Home balance carousel.
const List<AssetType> homeCarouselAssets = [
  AssetType.btc,
  AssetType.usdt,
  AssetType.usdc,
];

/// Tracks the active asset currently in view in the Home balance carousel.
final selectedHomeAssetProvider =
    StateProvider<AssetType>((ref) => AssetType.btc);

/// Multi-asset horizontal swipeable balance carousel for Hanbova Home.
class AssetBalanceCarousel extends ConsumerStatefulWidget {
  final VoidCallback? onEnvironmentTap;
  final String? environmentLabel;

  const AssetBalanceCarousel({
    super.key,
    this.onEnvironmentTap,
    this.environmentLabel,
  });

  @override
  ConsumerState<AssetBalanceCarousel> createState() =>
      _AssetBalanceCarouselState();
}

class _AssetBalanceCarouselState extends ConsumerState<AssetBalanceCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.93,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    ref.read(selectedHomeAssetProvider.notifier).state =
        homeCarouselAssets[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final privacy = ref.watch(privacyProvider);
    final demoState = ref.watch(demoModeProvider);
    final currency = ref.watch(currencyProvider);
    final rateProvider = ref.watch(exchangeRateProvider);
    final cashuBalanceAsync = ref.watch(cashuBalanceProvider);

    final cashuBalance = cashuBalanceAsync.valueOrNull ??
        const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
    final spendableSats = demoState.isEnabled
        ? demoState.availableBalanceSats
        : cashuBalance.spendableSats;

    final isBtcLoading = !demoState.isEnabled &&
        (cashuBalanceAsync.isLoading ||
            (!cashuBalanceAsync.hasValue && !cashuBalanceAsync.hasError));
    final isBtcError = !demoState.isEnabled && cashuBalanceAsync.hasError;

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14.0;
    final carouselHeight =
        184.0 + (textScale > 1.1 ? (textScale - 1.0) * 110.0 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carousel Header Toolbar: Section title + Environment + Visibility toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Balances',
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.environmentLabel != null &&
                        widget.environmentLabel!.isNotEmpty)
                      InkWell(
                        onTap: widget.onEnvironmentTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: colors.border.withValues(alpha: 0.8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 12, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(
                                widget.environmentLabel!,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('home_balance_visibility_toggle'),
                tooltip:
                    privacy.isBalanceHidden ? 'Show balances' : 'Hide balances',
                icon: Icon(
                  privacy.isBalanceHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    ref.read(privacyProvider.notifier).toggleBalanceHidden(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Horizontally Swipeable PageView
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            key: const Key('asset_balance_page_view'),
            controller: _pageController,
            itemCount: homeCarouselAssets.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final asset = homeCarouselAssets[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _buildAssetCard(
                  context,
                  asset: asset,
                  colors: colors,
                  isBalanceHidden: privacy.isBalanceHidden,
                  spendableSats: spendableSats,
                  demoState: demoState,
                  currency: currency,
                  rateProvider: rateProvider,
                  isLoading: asset == AssetType.btc && isBtcLoading,
                  hasError: asset == AssetType.btc && isBtcError,
                  onRetry: () => ref.invalidate(cashuBalanceProvider),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Animated Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            homeCarouselAssets.length,
            (index) => InkWell(
              onTap: () => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 22 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? colors.primary
                      : colors.textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(
    BuildContext context, {
    required AssetType asset,
    required HanbovaColors colors,
    required bool isBalanceHidden,
    required int spendableSats,
    required DemoModeState demoState,
    required FiatCurrency currency,
    required ExchangeRateProvider rateProvider,
    required bool isLoading,
    required bool hasError,
    required VoidCallback onRetry,
  }) {
    final isDark = context.isDark;

    // Determine asset-specific values
    String primaryDisplay;
    String secondaryDisplay;
    String semanticsAssetLabel;
    String detailRoute;

    final fiatPerUsd =
        rateProvider.getRate(currency) / rateProvider.getRate(FiatCurrency.usd);

    switch (asset) {
      case AssetType.btc:
        semanticsAssetLabel = 'Bitcoin balance';
        detailRoute = '/money/bitcoin';
        if (isBalanceHidden) {
          primaryDisplay = '•••••• BTC';
          secondaryDisplay = '≈ ••••••';
        } else {
          final btcAmount = spendableSats / 100000000.0;
          primaryDisplay = '${btcAmount.toStringAsFixed(8)} BTC';
          secondaryDisplay =
              '≈ ${currency.format(spendableSats, rateProvider)}';
        }
        break;

      case AssetType.usdt:
        semanticsAssetLabel = 'Tether balance';
        detailRoute = '/money/usdt';
        final usdtBalance =
            demoState.isEnabled ? demoState.demoUsdtBalance : 0.0;
        if (isBalanceHidden) {
          primaryDisplay = '•••••• USDT';
          secondaryDisplay = '≈ ••••••';
        } else {
          primaryDisplay = '${usdtBalance.toStringAsFixed(2)} USDT';
          final converted = usdtBalance * fiatPerUsd;
          secondaryDisplay = '≈ ${currency.formatFiat(converted)}';
        }
        break;

      case AssetType.usdc:
        semanticsAssetLabel = 'USD Coin balance';
        detailRoute = '/money/usdc';
        final usdcBalance =
            demoState.isEnabled ? demoState.demoUsdcBalance : 0.0;
        if (isBalanceHidden) {
          primaryDisplay = '•••••• USDC';
          secondaryDisplay = '≈ ••••••';
        } else {
          primaryDisplay = '${usdcBalance.toStringAsFixed(2)} USDC';
          final converted = usdcBalance * fiatPerUsd;
          secondaryDisplay = '≈ ${currency.formatFiat(converted)}';
        }
        break;
    }

    final cardBorderColor = asset == AssetType.btc
        ? colors.primary.withValues(alpha: isDark ? 0.35 : 0.25)
        : asset.color.withValues(alpha: isDark ? 0.35 : 0.25);

    return Semantics(
      label: '$semanticsAssetLabel, $primaryDisplay, $secondaryDisplay',
      button: true,
      child: InkWell(
        key: Key('carousel_card_${asset.symbol.toLowerCase()}'),
        onTap: () => context.push(detailRoute),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Asset Icon + Name + Ticker Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: asset.color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            asset.icon,
                            color: asset.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            asset.name == 'Tether USD' ? 'Tether' : asset.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: asset.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asset.symbol,
                      style: TextStyle(
                        color: asset.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // Middle: Primary & Secondary Balances (or Loading/Error)
              if (isLoading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updating balance…',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ] else if (hasError) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance unavailable',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary),
                    ),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 32),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        primaryDisplay,
                        style: AppTypography.displaySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        secondaryDisplay,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Bottom Row: Status label & companion info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      asset == AssetType.btc
                          ? 'Available to spend'
                          : 'Available balance',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (asset == AssetType.btc &&
                      !isBalanceHidden &&
                      !isLoading &&
                      !hasError) ...[
                    Flexible(
                      child: Text(
                        '${Formatters.formatSatsNumber(spendableSats)} sats',
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else if (asset != AssetType.btc) ...[
                    Flexible(
                      child: Text(
                        demoState.isEnabled ? 'Demo Balance' : 'Coming soon',
                        style: AppTypography.caption.copyWith(
                          color: demoState.isEnabled
                              ? colors.primary
                              : const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
