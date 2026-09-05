import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/hanbova_rate_card.dart';
import '../../wallet/domain/asset_model.dart';

class ConversionFlowScreen extends ConsumerStatefulWidget {
  final AssetType initialFromAsset;
  final AssetType initialToAsset;

  const ConversionFlowScreen({
    super.key,
    this.initialFromAsset = AssetType.btc,
    this.initialToAsset = AssetType.usdt,
  });

  @override
  ConsumerState<ConversionFlowScreen> createState() =>
      _ConversionFlowScreenState();
}

class _ConversionFlowScreenState extends ConsumerState<ConversionFlowScreen> {
  late AssetType _fromAsset;
  late AssetType _toAsset;
  final TextEditingController _amountController = TextEditingController();

  ConversionLifecycleStatus _status = ConversionLifecycleStatus.quoted;
  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  final bool _simulateUncertain = false;

  // Static sample conversion rates (1 BTC = 64,820 USD; 1 sat = 0.0006482 USD)
  static const double _btcUsdRate = 64820.0;
  static const double _feePercent = 0.0025; // 0.25%

  @override
  void initState() {
    super.initState();
    _fromAsset = widget.initialFromAsset;
    _toAsset = widget.initialToAsset != widget.initialFromAsset
        ? widget.initialToAsset
        : (widget.initialFromAsset == AssetType.btc
            ? AssetType.usdt
            : AssetType.btc);
    _amountController.text = _fromAsset == AssetType.btc ? '100000' : '50.00';
    _startQuoteTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _startQuoteTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _status = ConversionLifecycleStatus.quoted;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _status = ConversionLifecycleStatus.quoteExpired;
        });
      }
    });
  }

  void _refreshQuote() {
    setState(() => _status = ConversionLifecycleStatus.quoteLoading);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _startQuoteTimer();
      }
    });
  }

  void _swapAssets() {
    setState(() {
      final temp = _fromAsset;
      _fromAsset = _toAsset;
      _toAsset = temp;
      _amountController.text = _fromAsset == AssetType.btc ? '100000' : '50.00';
      _refreshQuote();
    });
  }

  double _parseInputAmount() {
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
  }

  double _calculateReceiveAmount() {
    final input = _parseInputAmount();
    if (input <= 0) return 0.0;

    double grossReceive;
    if (_fromAsset == AssetType.btc && _toAsset.isStablecoin) {
      // sats to USD
      grossReceive = (input / 100000000.0) * _btcUsdRate;
    } else if (_fromAsset.isStablecoin && _toAsset == AssetType.btc) {
      // USD to sats
      grossReceive = (input / _btcUsdRate) * 100000000.0;
    } else {
      // Stablecoin to Stablecoin
      grossReceive = input * 0.999;
    }
    return grossReceive * (1 - _feePercent);
  }

  double _calculateFee() {
    final input = _parseInputAmount();
    return input * _feePercent;
  }

  String _formatRateString() {
    if (_fromAsset == AssetType.btc && _toAsset.isStablecoin) {
      return '1 BTC ≈ \$64,820 ${_toAsset.symbol}';
    } else if (_fromAsset.isStablecoin && _toAsset == AssetType.btc) {
      return '1 ${_fromAsset.symbol} ≈ 1,542 sats';
    } else {
      return '1 ${_fromAsset.symbol} ≈ 0.999 ${_toAsset.symbol}';
    }
  }

  String _formatAmountDisplay(double val, AssetType asset) {
    if (asset == AssetType.btc) {
      return '${Formatters.formatSats(val.round())} sats';
    }
    return '\$${val.toStringAsFixed(2)} ${asset.symbol}';
  }

  void _showReviewModal(BuildContext context) {
    if (_status == ConversionLifecycleStatus.quoteExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote expired. Please refresh.')),
      );
      return;
    }

    final colors = context.colors;
    final isDark = context.isDark;
    final inputAmount = _parseInputAmount();
    final receiveAmount = _calculateReceiveAmount();
    final fee = _calculateFee();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isConfirming =
                _status == ConversionLifecycleStatus.confirming ||
                    _status == ConversionLifecycleStatus.processing;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: colors.border),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Review Conversion',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SAMPLE QUOTE • DEMO DATA',
                      style: AppTypography.caption.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Conversion Summary Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color:
                            isDark ? colors.background : colors.surfaceElevated,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          _buildReviewRow(
                            'You send',
                            _formatAmountDisplay(inputAmount, _fromAsset),
                            colors,
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          _buildReviewRow(
                            'You receive',
                            _formatAmountDisplay(receiveAmount, _toAsset),
                            colors,
                            isBold: true,
                            valueColor: colors.primary,
                          ),
                          const Divider(height: 16),
                          _buildReviewRow(
                            'Exchange rate',
                            _formatRateString(),
                            colors,
                          ),
                          const Divider(height: 16),
                          _buildReviewRow(
                            'Conversion fee (0.25%)',
                            _formatAmountDisplay(fee, _fromAsset),
                            colors,
                          ),
                          const Divider(height: 16),
                          _buildReviewRow(
                            'Total deducted',
                            _formatAmountDisplay(inputAmount, _fromAsset),
                            colors,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quote expiry row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: _secondsRemaining < 10
                              ? colors.danger
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _secondsRemaining > 0
                              ? 'Quote expires in $_secondsRemaining seconds'
                              : 'Quote expired',
                          style: AppTypography.caption.copyWith(
                            color: _secondsRemaining < 10
                                ? colors.danger
                                : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Confirm Button
                    ElevatedButton(
                      key: const Key('confirm_conversion_button'),
                      onPressed: isConfirming || _secondsRemaining == 0
                          ? null
                          : () => _executeConversionConfirmation(
                                setModalState: setModalState,
                                inputAmount: inputAmount,
                                receiveAmount: receiveAmount,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdRadius),
                      ),
                      child: isConfirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Conversion',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewRow(
    String label,
    String value,
    HanbovaColors colors, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor ?? colors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _executeConversionConfirmation({
    required StateSetter setModalState,
    required double inputAmount,
    required double receiveAmount,
  }) async {
    setModalState(() {
      _status = ConversionLifecycleStatus.confirming;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setModalState(() {
      _status = ConversionLifecycleStatus.processing;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Navigator.of(context).pop(); // close review modal

    if (_simulateUncertain) {
      _showUncertainResult(context);
    } else {
      _showSuccessResult(
        context,
        inputAmount: inputAmount,
        receiveAmount: receiveAmount,
      );
    }
  }

  void _showSuccessResult(
    BuildContext context, {
    required double inputAmount,
    required double receiveAmount,
  }) {
    setState(() => _status = ConversionLifecycleStatus.completed);
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.border),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Conversion Completed',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatAmountDisplay(inputAmount, _fromAsset)}\nto\n${_formatAmountDisplay(receiveAmount, _toAsset)}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/activity');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdRadius),
                        ),
                        child: Text(
                          'View Transaction',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/money');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdRadius),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUncertainResult(BuildContext context) {
    setState(() => _status = ConversionLifecycleStatus.uncertain);
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.border),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: colors.warning,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Conversion Processing',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your conversion is being verified across nodes. It has not failed. Check the Activity tab shortly for final settlement.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/activity');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdRadius),
                  ),
                  child: const Text('View Pending Activity'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final demoState = ref.watch(demoModeProvider);

    final inputAmount = _parseInputAmount();
    final receiveAmount = _calculateReceiveAmount();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Convert Assets',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _secondsRemaining == 0
                  ? colors.primary
                  : colors.textSecondary,
            ),
            onPressed: _refreshQuote,
            tooltip: 'Refresh Quote',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            // Demo notice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.smRadius,
                border:
                    Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SAMPLE QUOTES • DEMO DATA • NO LIVE SWAPS',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Hanbova Platform Settlement Rate
            const HanbovaRateCard(),
            const SizedBox(height: AppSpacing.md),

            // From Asset Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'From',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildAssetPickerDropdown(
                        selected: _fromAsset,
                        onChanged: (newAsset) {
                          if (newAsset != null && newAsset != _fromAsset) {
                            setState(() {
                              _fromAsset = newAsset;
                              if (_toAsset == _fromAsset) {
                                _toAsset = _fromAsset == AssetType.btc
                                    ? AssetType.usdt
                                    : AssetType.btc;
                              }
                              _refreshQuote();
                            });
                          }
                        },
                        colors: colors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('conversion_amount_input'),
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.headline.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: colors.textTertiary.withValues(alpha: 0.4),
                      ),
                      suffixText: _fromAsset.symbol,
                      suffixStyle: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  // Quick percentage chips
                  Row(
                    children: [
                      _buildPercentChip('25%', () {
                        setState(() {
                          _amountController.text =
                              _fromAsset == AssetType.btc ? '25000' : '12.50';
                          _refreshQuote();
                        });
                      }, colors),
                      const SizedBox(width: 8),
                      _buildPercentChip('50%', () {
                        setState(() {
                          _amountController.text =
                              _fromAsset == AssetType.btc ? '50000' : '25.00';
                          _refreshQuote();
                        });
                      }, colors),
                      const SizedBox(width: 8),
                      _buildPercentChip('MAX', () {
                        setState(() {
                          _amountController.text = _fromAsset == AssetType.btc
                              ? (demoState.isEnabled ? '1800000' : '0')
                              : (demoState.isEnabled ? '1250.00' : '0.00');
                          _refreshQuote();
                        });
                      }, colors),
                    ],
                  ),
                ],
              ),
            ),

            // Swap Button Divider
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: IconButton.filled(
                  icon: const Icon(Icons.swap_vert_rounded, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceElevated,
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.border),
                  ),
                  onPressed: _swapAssets,
                ),
              ),
            ),

            // To Asset Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'To (Estimated)',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildAssetPickerDropdown(
                        selected: _toAsset,
                        onChanged: (newAsset) {
                          if (newAsset != null && newAsset != _toAsset) {
                            setState(() {
                              _toAsset = newAsset;
                              if (_fromAsset == _toAsset) {
                                _fromAsset = _toAsset == AssetType.btc
                                    ? AssetType.usdt
                                    : AssetType.btc;
                              }
                              _refreshQuote();
                            });
                          }
                        },
                        colors: colors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmountDisplay(receiveAmount, _toAsset),
                    style: AppTypography.headline.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quote Details Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? colors.background : colors.surfaceElevated,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Indicative Rate',
                          style: AppTypography.caption
                              .copyWith(color: colors.textSecondary)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_formatRateString(),
                            style: AppTypography.caption.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Conversion Fee',
                          style: AppTypography.caption
                              .copyWith(color: colors.textSecondary)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('0.25% (included)',
                            style: AppTypography.caption.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quote Expiry',
                          style: AppTypography.caption
                              .copyWith(color: colors.textSecondary)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _secondsRemaining > 0
                              ? '$_secondsRemaining seconds'
                              : 'Expired (Tap Refresh)',
                          style: AppTypography.caption.copyWith(
                            color: _secondsRemaining < 10
                                ? colors.danger
                                : colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Review Conversion CTA
            ElevatedButton(
              key: const Key('review_conversion_button'),
              onPressed: inputAmount > 0 &&
                      _status != ConversionLifecycleStatus.quoteExpired
                  ? () => _showReviewModal(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              child: Text(
                _status == ConversionLifecycleStatus.quoteExpired
                    ? 'Quote Expired • Tap to Refresh'
                    : 'Review Conversion',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetPickerDropdown({
    required AssetType selected,
    required ValueChanged<AssetType?> onChanged,
    required HanbovaColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AssetType>(
          value: selected,
          icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textPrimary),
          dropdownColor: colors.surfaceCard,
          items: AssetType.values.map((asset) {
            return DropdownMenuItem(
              value: asset,
              child: Row(
                children: [
                  Icon(asset.icon, size: 16, color: asset.color),
                  const SizedBox(width: 6),
                  Text(
                    asset.symbol,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPercentChip(
      String label, VoidCallback onTap, HanbovaColors colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
