import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/domain/asset_model.dart';
import '../domain/instant_send_controller.dart';
import 'instant_send_review.dart';

class SendScreen extends ConsumerStatefulWidget {
  final String? initialInvoice;
  final String? initialRecipient;
  final AssetType initialAsset;

  const SendScreen({
    super.key,
    this.initialInvoice,
    this.initialRecipient,
    this.initialAsset = AssetType.btc,
  });

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  late AssetType _selectedAsset;
  late final TextEditingController _invoiceController;

  // Stablecoin send state
  final TextEditingController _stablecoinAddressController =
      TextEditingController();
  final TextEditingController _stablecoinAmountController =
      TextEditingController(text: '50.00');
  String get _defaultStablecoinNetwork =>
      _selectedAsset.defaultSettlementNetwork;

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _successMessage;
  InstantSendQuote? _activeReview;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.initialAsset;
    _invoiceController = TextEditingController(
      text: widget.initialInvoice ?? widget.initialRecipient ?? '',
    );
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _stablecoinAddressController.dispose();
    _stablecoinAmountController.dispose();
    super.dispose();
  }

  Future<void> _pasteToInvoice() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _invoiceController.text = data.text!.trim();
      });
    }
  }

  Future<void> _pasteToStablecoinAddress() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _stablecoinAddressController.text = data.text!.trim();
      });
    }
  }

  Future<void> _fetchQuote() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _activeReview = null;
    });

    try {
      final review = await ref
          .read(instantSendControllerProvider)
          .prepare(_invoiceController.text);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeReview = review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final friendlyMessage = UserFacingErrorMapper.from(e).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _executePayment() async {
    if (_isLoading || _activeReview == null) return;

    setState(() => _isLoading = true);
    final review = _activeReview!;

    try {
      await ref.read(instantSendControllerProvider).confirm(review);
      ref.invalidate(cashuBalanceProvider);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final friendlyMessage = UserFacingErrorMapper.from(e).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _executeStablecoinSend(HanbovaColors colors) async {
    final amount = double.tryParse(_stablecoinAmountController.text) ?? 0.0;
    final address = _stablecoinAddressController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Deduct demo stablecoin balance if demo mode is active
    ref.read(demoModeProvider.notifier).deductStablecoin(
          asset: _selectedAsset,
          amount: amount,
        );

    final shortAddr = address.isNotEmpty
        ? (address.length > 12
            ? "${address.substring(0, 6)}...${address.substring(address.length - 4)}"
            : address)
        : "TRC-20 Recipient";

    // Record stablecoin transaction with default TRC-20 settlement metadata
    await ref.read(transactionsProvider.notifier).addTransaction(
          TransactionModel(
            id: 'tx_send_${DateTime.now().millisecondsSinceEpoch}',
            type: _selectedAsset == AssetType.usdt
                ? TransactionType.usdtSent
                : TransactionType.usdcSent,
            status: TransactionStatus.completed,
            amountSats: 0,
            recipientOrSender: shortAddr,
            description:
                'Sent \$${amount.toStringAsFixed(2)} ${_selectedAsset.symbol} over $_defaultStablecoinNetwork',
            createdAt: DateTime.now(),
            fiatAmount: amount,
            fiatCurrency: 'USD',
            sourceAsset: _selectedAsset.symbol,
            sourceAmount: amount,
            destinationAsset: _selectedAsset.symbol,
            destinationAmount: amount,
            metadata: {
              'settlementNetwork': _defaultStablecoinNetwork,
            },
            hanbovaReference:
                'HNBV-TRC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          ),
        );

    setState(() {
      _isLoading = false;
      _isSuccess = true;
      _successMessage =
          'Sent \$${amount.toStringAsFixed(2)} ${_selectedAsset.symbol} to $shortAddr over $_defaultStablecoinNetwork';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Send ${_selectedAsset.symbol}',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: colors.primary),
            tooltip: 'Scan QR',
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isSuccess
            ? _buildSuccessView(colors, isDark)
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Available Balance Header Card
                      _buildBalanceHeaderCard(colors, isDark),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Asset Selector Prompt
                      Text(
                        'What are you sending?',
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Multi-Asset Selection Row
                      Row(
                        children: [
                          _buildAssetChip(AssetType.btc, colors),
                          const SizedBox(width: 8),
                          _buildAssetChip(AssetType.usdt, colors),
                          const SizedBox(width: 8),
                          _buildAssetChip(AssetType.usdc, colors),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Asset Specific Send View
                      if (_selectedAsset == AssetType.btc)
                        _buildBitcoinSendForm(colors, isDark)
                      else
                        _buildStablecoinSendForm(colors, isDark),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceHeaderCard(HanbovaColors colors, bool isDark) {
    final demoState = ref.watch(demoModeProvider);
    final currency = ref.watch(currencyProvider);
    final rateProvider = ref.watch(exchangeRateProvider);
    final cashuBalanceAsync = ref.watch(cashuBalanceProvider);

    final cashuBalance = cashuBalanceAsync.valueOrNull ??
        const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
    final spendableSats = demoState.isEnabled
        ? demoState.availableBalanceSats
        : cashuBalance.spendableSats;

    String balanceText;
    String fiatText;

    final fiatPerUsd =
        rateProvider.getRate(currency) / rateProvider.getRate(FiatCurrency.usd);

    if (_selectedAsset == AssetType.btc) {
      balanceText = '${Formatters.formatSatsNumber(spendableSats)} sats';
      fiatText = '≈ ${currency.format(spendableSats, rateProvider)}';
    } else if (_selectedAsset == AssetType.usdt) {
      final bal = demoState.isEnabled ? demoState.demoUsdtBalance : 0.0;
      balanceText = '\$${bal.toStringAsFixed(2)} USDT';
      fiatText = '≈ ${currency.formatFiat(bal * fiatPerUsd)}';
    } else {
      final bal = demoState.isEnabled ? demoState.demoUsdcBalance : 0.0;
      balanceText = '\$${bal.toStringAsFixed(2)} USDC';
      fiatText = '≈ ${currency.formatFiat(bal * fiatPerUsd)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: _selectedAsset.color.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedAsset.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedAsset.icon,
                    color: _selectedAsset.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Available Balance',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balanceText,
                          style: AppTypography.titleSmall.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                fiatText,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetChip(AssetType asset, HanbovaColors colors) {
    final isSelected = _selectedAsset == asset;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAsset = asset;
          _activeReview = null;
          ref.read(instantSendControllerProvider).reset();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? asset.color : colors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? asset.color : colors.border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: asset.color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              asset.icon,
              size: 16,
              color: isSelected ? Colors.white : asset.color,
            ),
            const SizedBox(width: 6),
            Text(
              asset.symbol,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitcoinSendForm(HanbovaColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lightning Info Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Instant payments settle immediately on the Lightning Network and are final.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Invoice Input Card
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
                  Flexible(
                    child: Text(
                      'Destination Invoice',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_activeReview == null && !_isLoading)
                    Row(
                      children: [
                        InkWell(
                          onTap: _pasteToInvoice,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_paste_rounded,
                                    size: 12, color: colors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'PASTE',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => context.push('/scan'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded,
                                    size: 12, color: colors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'SCAN',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _invoiceController,
                maxLines: 3,
                enabled: _activeReview == null && !_isLoading,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'BOLT11 Lightning invoice',
                  hintText: 'Paste a Lightning invoice for the active network',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => context.push('/scan'),
                  ),
                ),
                validator: (val) {
                  if (_selectedAsset != AssetType.btc) return null;
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a Lightning invoice';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),

        if (_activeReview != null) ...[
          const SizedBox(height: AppSpacing.lg),
          InstantSendReviewCard(review: _activeReview!),
        ],
        const SizedBox(height: AppSpacing.xl),

        if (_activeReview == null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bitcoinOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bolt_rounded, size: 20),
            label: _isLoading
                ? const Text('Calculating Fees...')
                : const Text(
                    'Review Invoice & Fees',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _executePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: _isLoading
                ? const Text('Settling Payment...')
                : const Text(
                    'Confirm & Pay Instantly',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _activeReview = null;
                      ref.read(instantSendControllerProvider).reset();
                    });
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            child: Text(
              'Change Invoice',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStablecoinSendForm(HanbovaColors colors, bool isDark) {
    final demoState = ref.watch(demoModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!demoState.isEnabled)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_selectedAsset.symbol} transfers are currently in Coming Soon status. Simulated test sends are supported in Demo Mode.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Recipient Address Box
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
                  Flexible(
                    child: Text(
                      'Recipient',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: _pasteToStablecoinAddress,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_paste_rounded,
                                  size: 12, color: _selectedAsset.color),
                              const SizedBox(width: 4),
                              Text(
                                'PASTE',
                                style: TextStyle(
                                  color: _selectedAsset.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => context.push('/scan'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded,
                                  size: 12, color: _selectedAsset.color),
                              const SizedBox(width: 4),
                              Text(
                                'SCAN',
                                style: TextStyle(
                                  color: _selectedAsset.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('stablecoin_recipient_input'),
                controller: _stablecoinAddressController,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: '${_selectedAsset.symbol} Recipient Address',
                  hintText: 'Enter TRC-20 address',
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => context.push('/scan'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Amount Input Card
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
              Text(
                'Amount to Send',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('stablecoin_amount_input'),
                controller: _stablecoinAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (${_selectedAsset.symbol})',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixText: _selectedAsset.symbol,
                  suffixStyle: TextStyle(
                    color: _selectedAsset.color,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Network Fee Estimate
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station_rounded,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated Network Fee',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const Text(
                '≈ \$1.00 (Sample fixture)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        ElevatedButton(
          key: const Key('send_stablecoin_submit_button'),
          onPressed: _isLoading ? null : () => _executeStablecoinSend(colors),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAsset.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Review & Send ${_selectedAsset.symbol}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(HanbovaColors colors, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Transfer Submitted!',
              style: AppTypography.headline.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Text(
                _successMessage ??
                    'Lightning payment settled instantly and confirmed.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
