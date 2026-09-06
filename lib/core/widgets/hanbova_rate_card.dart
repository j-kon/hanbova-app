import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rates/all_rates_screen.dart';
import '../market/market_provider.dart';
import '../rates/hanbova_all_rates_provider.dart';
import '../rates/hanbova_rate.dart';
import '../rates/hanbova_rate_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable customer-facing Hanbova Platform Rate Card.
///
/// Displays the current settlement conversion rate offered through Hanbova's
/// configured provider across LIVE, STALE, LOADING, UNAVAILABLE, and DEMO states.
///
/// Supports scoping to a specific [market] (e.g. 'KE') or [currency] (e.g. 'KES').
/// When omitted, adapts to the user's active market context from [marketProvider].
class HanbovaRateCard extends StatelessWidget {
  final bool isInline;
  final VoidCallback? onTap;
  final String? market;
  final String? currency;

  const HanbovaRateCard({
    super.key,
    this.isInline = false,
    this.onTap,
    this.market,
    this.currency,
  });

  /// Factory constructor for a compact inline presentation.
  const HanbovaRateCard.inline({
    super.key,
    this.onTap,
    this.market,
    this.currency,
  }) : isInline = true;

  String _formatRelativeTime(DateTime time, bool isStale) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 15) {
      return isStale ? 'Last updated just now' : 'Updated just now';
    } else if (difference.inSeconds < 60) {
      return isStale
          ? 'Last updated ${difference.inSeconds}s ago'
          : 'Updated ${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return isStale ? 'Last updated ${mins}m ago' : 'Updated ${mins}m ago';
    } else {
      final hours = difference.inHours;
      return isStale ? 'Last updated ${hours}h ago' : 'Updated ${hours}h ago';
    }
  }

  HanbovaRateState _resolveRateState(WidgetRef ref) {
    final targetMarket = market?.toUpperCase();
    final targetCurrency = currency?.toUpperCase();

    // 1. If explicitly targeting a market or currency
    if (targetMarket != null || targetCurrency != null) {
      // If targeting NG or NGN, check if hanbovaRateProvider has a valid rate
      // (preserves test overrides & existing NGN provider behavior)
      if (targetMarket == 'NG' || targetCurrency == 'NGN') {
        try {
          final ngRateState = ref.watch(hanbovaRateProvider);
          if (ngRateState.rate != null || ngRateState.isUnavailable) {
            return ngRateState;
          }
        } catch (_) {}
      }

      try {
        final allRates = ref.watch(allHanbovaRatesProvider);
        final match =
            allRates.findBy(market: targetMarket, currency: targetCurrency);
        if (match != null && match.rate != null) {
          return match.toRateState(allRates.lastFetched);
        }
        if (allRates.isLoading) {
          return const HanbovaRateState(status: HanbovaRateStatus.loading);
        }
        if (match != null) {
          return match.toRateState(allRates.lastFetched);
        }
      } catch (_) {}

      return const HanbovaRateState(status: HanbovaRateStatus.unavailable);
    }

    // 2. No explicit market or currency provided: check user active market
    try {
      final userMarket = ref.watch(marketProvider);
      final activeMarketCode = userMarket.activeMarket.toUpperCase();

      if (activeMarketCode != 'NG') {
        final allRates = ref.watch(allHanbovaRatesProvider);
        final match = allRates.findBy(market: activeMarketCode);
        if (match != null && match.rate != null) {
          return match.toRateState(allRates.lastFetched);
        }
        if (allRates.isLoading) {
          return const HanbovaRateState(status: HanbovaRateStatus.loading);
        }
      }
    } catch (_) {}

    // Default / NG market: use hanbovaRateProvider (preserves test overrides)
    return ref.watch(hanbovaRateProvider);
  }

  void _onRetry(WidgetRef ref) {
    try {
      ref.read(hanbovaRateProvider.notifier).refresh();
    } catch (_) {}
    try {
      ref.read(allHanbovaRatesProvider.notifier).refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Graceful fallback if ProviderScope is absent (e.g. isolated test harnesses)
    try {
      ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, _) {
        final rateState = _resolveRateState(ref);
        final colors = context.colors;
        final isDark = context.isDark;

        if (isInline) {
          return _buildInlineCard(context, ref, rateState, colors, isDark);
        }

        return _buildStandardCard(context, ref, rateState, colors, isDark);
      },
    );
  }

  Widget _buildStandardCard(
    BuildContext context,
    WidgetRef ref,
    HanbovaRateState state,
    HanbovaColors colors,
    bool isDark,
  ) {
    final (badgeText, badgeColor, dotColor) = switch (state.status) {
      HanbovaRateStatus.live => (
          'Live',
          const Color(0xFF10B981).withValues(alpha: 0.15),
          const Color(0xFF10B981)
        ),
      HanbovaRateStatus.stale => (
          'Stale',
          Colors.amber.withValues(alpha: 0.15),
          Colors.amber
        ),
      HanbovaRateStatus.demo => (
          'Demo Rate',
          colors.primary.withValues(alpha: 0.15),
          colors.primary
        ),
      HanbovaRateStatus.unavailable => (
          'Unavailable',
          colors.textSecondary.withValues(alpha: 0.12),
          colors.textSecondary
        ),
      HanbovaRateStatus.loading => (
          'Updating…',
          colors.surfaceElevated,
          colors.textSecondary
        ),
    };

    final isUnavailable = state.status == HanbovaRateStatus.unavailable;
    final isLoading = state.status == HanbovaRateStatus.loading;
    final rate = state.rate;

    final updatedText = rate != null
        ? _formatRelativeTime(rate.updatedAt, state.isStale)
        : (isUnavailable ? 'Check connection' : 'Checking provider…');

    return Semantics(
      label: 'Hanbova Platform Rate. ${rate?.display ?? "Loading"}',
      container: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('hanbova_rate_card_tap'),
          onTap: onTap ??
              () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllRatesScreen(),
                    ),
                  ),
          borderRadius: AppRadius.mdRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: state.isStale
                    ? Colors.amber.withValues(alpha: 0.3)
                    : colors.border,
                width: 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Title + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.currency_exchange_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Hanbova Rate',
                                style: AppTypography.titleMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: AppRadius.xsRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  badgeText,
                                  style: AppTypography.caption.copyWith(
                                    color: dotColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Main Rate Value or Fallback
                if (isUnavailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rate temporarily unavailable',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _onRetry(ref),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isLoading && rate == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fetching latest rate…',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rate?.display ?? r'$1 = ₦1,365.00',
                      style: AppTypography.headline.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),

                // Footer: Settlement corridor + relative timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${rate?.settlementAsset ?? "USDT"} → ${rate?.quote ?? (currency?.toUpperCase() ?? (market?.toUpperCase() ?? "NGN"))}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        updatedText,
                        style: AppTypography.caption.copyWith(
                          color: state.isStale
                              ? Colors.amber
                              : colors.textTertiary,
                          fontWeight: state.isStale
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCard(
    BuildContext context,
    WidgetRef ref,
    HanbovaRateState state,
    HanbovaColors colors,
    bool isDark,
  ) {
    final rate = state.rate;
    final dotColor = switch (state.status) {
      HanbovaRateStatus.live => const Color(0xFF10B981),
      HanbovaRateStatus.stale => Colors.amber,
      HanbovaRateStatus.demo => colors.primary,
      _ => colors.textSecondary,
    };

    return InkWell(
      onTap: onTap ??
          () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllRatesScreen(),
                ),
              ),
      borderRadius: AppRadius.smRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Hanbova Rate:',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                state.isUnavailable
                    ? 'Unavailable'
                    : (rate?.display ?? 'Loading…'),
                style: AppTypography.caption.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${rate?.settlementAsset ?? "USDT"} → ${rate?.quote ?? (currency?.toUpperCase() ?? "NGN")}',
              style: AppTypography.caption.copyWith(
                color: colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
