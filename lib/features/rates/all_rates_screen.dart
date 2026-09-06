import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rates/hanbova_all_rates_provider.dart';
import '../../../core/rates/hanbova_rate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';

/// Full-screen view showing the Hanbova Platform Rate for every supported market.
///
/// Each market entry is independently live / stale / unavailable.
/// A single unavailable market never blocks the rest of the page.
class AllRatesScreen extends ConsumerStatefulWidget {
  const AllRatesScreen({super.key});

  @override
  ConsumerState<AllRatesScreen> createState() => _AllRatesScreenState();
}

class _AllRatesScreenState extends ConsumerState<AllRatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allHanbovaRatesProvider.notifier).fetchAllRates(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allHanbovaRatesProvider);
    final colors = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, colors, state),
      body: _buildBody(context, state, colors, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HanbovaColors colors,
    HanbovaAllRatesState state,
  ) {
    return AppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hanbova Rates',
            style: AppTypography.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.lastFetched != null)
            Text(
              _formatFetchTime(state.lastFetched!),
              style: AppTypography.caption.copyWith(
                color: colors.textTertiary,
                fontSize: 10,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh all rates',
          icon: Icon(Icons.refresh_rounded,
              color: colors.textSecondary, size: 22),
          onPressed: () => ref.read(allHanbovaRatesProvider.notifier).refresh(),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    HanbovaAllRatesState state,
    HanbovaColors colors,
    bool isDark,
  ) {
    if (state.isLoading && !state.hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fetching platform rates…',
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.status == HanbovaAllRatesStatus.error && !state.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 52, color: colors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage ?? 'Platform rates temporarily unavailable',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(allHanbovaRatesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: colors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.read(allHanbovaRatesProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Header notice
          SliverToBoxAdapter(
            child: _buildProviderBanner(colors, state),
          ),
          // Market rate list
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            sliver: SliverList.separated(
              itemCount: state.markets.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final market = state.markets[i];
                return _MarketRateRow(
                  marketState: market,
                  isDark: isDark,
                  colors: colors,
                );
              },
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildProviderBanner(
      HanbovaColors colors, HanbovaAllRatesState state) {
    final isAllDemo =
        state.markets.every((m) => m.status == HanbovaRateStatus.demo);

    if (!isAllDemo) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo rates — provider not yet connected',
              style: AppTypography.caption.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatFetchTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 15) return 'Updated just now';
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }
}

// ---------------------------------------------------------------------------
// Individual market row widget
// ---------------------------------------------------------------------------

class _MarketRateRow extends StatelessWidget {
  final HanbovaMarketRateState marketState;
  final bool isDark;
  final HanbovaColors colors;

  const _MarketRateRow({
    required this.marketState,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final rate = marketState.rate;
    final isUnavailable = marketState.status == HanbovaRateStatus.unavailable;
    final isLoading = marketState.status == HanbovaRateStatus.loading;

    final (badgeText, dotColor, bgColor) = switch (marketState.status) {
      HanbovaRateStatus.live => (
          'Live',
          const Color(0xFF10B981),
          const Color(0xFF10B981),
        ),
      HanbovaRateStatus.stale => (
          'Stale',
          Colors.amber,
          Colors.amber,
        ),
      HanbovaRateStatus.demo => (
          'Demo',
          colors.primary,
          colors.primary,
        ),
      HanbovaRateStatus.unavailable => (
          'Unavailable',
          colors.textTertiary,
          colors.textTertiary,
        ),
      HanbovaRateStatus.loading => (
          '…',
          colors.textTertiary,
          colors.textTertiary,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: marketState.status == HanbovaRateStatus.stale
              ? Colors.amber.withValues(alpha: 0.35)
              : colors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          // Flag
          Text(
            marketState.flagEmoji,
            style: const TextStyle(fontSize: 28, height: 1),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Country name + currency
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marketState.countryName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  rate != null
                      ? '${rate.settlementAsset} → ${rate.quote}'
                      : marketState.currency,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Rate display / loading / unavailable
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUnavailable)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 14, color: colors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Unavailable',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                )
              else if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: colors.primary),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    rate?.display ?? '—',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: AppTypography.caption.copyWith(
                        color: dotColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
