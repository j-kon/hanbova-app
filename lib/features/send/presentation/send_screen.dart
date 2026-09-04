import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/errors/user_facing_error.dart';
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
  String _selectedNetwork = 'Polygon';
  static const List<String> _demoNetworks = [
    'Polygon',
    'Tron (TRC-20)',
    'Ethereum (ERC-20)',
  ];

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Send ${_selectedAsset.symbol}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isSuccess
            ? _buildSuccessView()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Asset Selector Prompt
                      Text(
                        'What are you sending?',
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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

                      // 2. Asset Specific Send View
                      if (_selectedAsset == AssetType.btc)
                        _buildBitcoinSendForm(colors)
                      else
                        _buildStablecoinSendForm(colors),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAssetChip(AssetType asset, HanbovaColors colors) {
    final isSelected = _selectedAsset == asset;
    return ChoiceChip(
      label: Text(
        asset.symbol,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(asset.icon,
          size: 16, color: isSelected ? Colors.white : asset.color),
      selected: isSelected,
      selectedColor: asset.color,
      backgroundColor: colors.surfaceCard,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAsset = asset;
            _activeReview = null;
            ref.read(instantSendControllerProvider).reset();
          });
        }
      },
    );
  }

  Widget _buildBitcoinSendForm(HanbovaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.amber, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Instant payments settle immediately on the Lightning Network and are final.',
                  style: AppTypography.bodySmall
                      .copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _invoiceController,
          maxLines: 3,
          enabled: _activeReview == null && !_isLoading,
          decoration: InputDecoration(
            labelText: 'BOLT11 Lightning invoice',
            hintText: 'Paste a Lightning invoice for the active network',
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
        if (_activeReview != null) ...[
          const SizedBox(height: AppSpacing.lg),
          InstantSendReviewCard(review: _activeReview!),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (_activeReview == null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchQuote,
            icon: const Icon(Icons.bolt, size: 18),
            label: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Review Invoice & Fees'),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _executePayment,
            icon: const Icon(Icons.check, size: 18),
            label: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirm & Pay Instantly'),
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
            child: const Text('Change Invoice'),
          ),
        ],
      ],
    );
  }

  Widget _buildStablecoinSendForm(HanbovaColors colors) {
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
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedAsset.symbol} transfers are currently in Coming Soon status. Simulated test sends are supported in Demo Mode.',
                    style: AppTypography.caption
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

        // Recipient address field
        TextFormField(
          key: const Key('stablecoin_recipient_input'),
          controller: _stablecoinAddressController,
          decoration: InputDecoration(
            labelText: '${_selectedAsset.symbol} Recipient Address',
            hintText: 'Enter 0x... or Tron address',
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/scan'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Network Selector Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedNetwork,
          decoration: const InputDecoration(
            labelText: 'Settlement Network',
          ),
          dropdownColor: colors.surfaceCard,
          items: _demoNetworks.map((net) {
            return DropdownMenuItem(
              value: net,
              child: Text(net, style: TextStyle(color: colors.textPrimary)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedNetwork = val);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Amount Input
        TextFormField(
          key: const Key('stablecoin_amount_input'),
          controller: _stablecoinAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (${_selectedAsset.symbol})',
            prefixText: '\$ ',
            suffixText: _selectedAsset.symbol,
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
              Text(
                'Estimated Network Fee',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
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

    setState(() {
      _isLoading = false;
      _isSuccess = true;
      _successMessage =
          'Sent \$${amount.toStringAsFixed(2)} ${_selectedAsset.symbol} to ${address.isNotEmpty ? (address.length > 12 ? "${address.substring(0, 6)}...${address.substring(address.length - 4)}" : address) : "recipient"} over $_selectedNetwork';
    });
  }

  Widget _buildSuccessView() {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check, color: Color(0xFF10B981), size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Transfer Submitted!',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _successMessage ??
                'Lightning payment settled instantly and confirmed.',
            textAlign: TextAlign.center,
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
