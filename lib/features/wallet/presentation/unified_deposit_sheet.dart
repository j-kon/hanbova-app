import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/notifications/in_app_notification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/consumer_error_translator.dart';
import '../../../core/utils/formatters.dart';

/// Unified Deposit Sheet supporting Lightning Invoice (NUT-04), On-Chain Bitcoin, and Cashu Token redeem
class UnifiedDepositSheet extends ConsumerStatefulWidget {
  const UnifiedDepositSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnifiedDepositSheet(),
    );
  }

  @override
  ConsumerState<UnifiedDepositSheet> createState() =>
      _UnifiedDepositSheetState();
}

class _UnifiedDepositSheetState extends ConsumerState<UnifiedDepositSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Lightning state
  final TextEditingController _amountController =
      TextEditingController(text: '5000');
  bool _isGeneratingInvoice = false;
  bool _isMinting = false;
  String? _generatedInvoice;
  String? _quoteId;
  String? _errorMessage;
  Timer? _pollTimer;

  // Cashu token state
  final TextEditingController _tokenController = TextEditingController();
  bool _isClaimingToken = false;
  String? _claimSuccessMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _startPollingQuote(String quoteId) {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (_quoteId != quoteId || !mounted) {
        timer.cancel();
        return;
      }
      await _checkQuoteStatusAndMint(quoteId, fromPolling: true);
    });
  }

  Future<void> _checkQuoteStatusAndMint(String quoteId,
      {bool fromPolling = false}) async {
    if (_isMinting || _quoteId != quoteId) return;

    try {
      final wallet = ref.read(cashuWalletServiceProvider);
      if (wallet == null) return;

      // 1. Check quote status with mint without triggering premature proof minting
      final statusResult = await wallet.checkMintQuoteStatus(quoteId);

      if (statusResult.isPaid) {
        _pollTimer?.cancel();
        if (_isMinting) return;
        setState(() => _isMinting = true);

        final minted = await wallet.mintQuote(quoteId);
        ref.invalidate(cashuBalanceProvider);
        ref.read(inAppNotificationProvider.notifier).show(
              title: 'Ecash Minted!',
              message:
                  'Deposited ${Formatters.formatSats(minted)} into your wallet',
              icon: Icons.bolt,
              type: InAppNotificationType.success,
            );

        if (mounted) {
          setState(() {
            _isMinting = false;
            _generatedInvoice = null;
            _quoteId = null;
            _errorMessage = null;
            _claimSuccessMessage =
                'Payment confirmed! Successfully minted $minted sats into your wallet.';
          });
        }
      } else if (!fromPolling) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Invoice is still unpaid (status: ${statusResult.state}). Please complete payment in your Lightning wallet.';
          });
        }
      }
    } catch (e) {
      if (!fromPolling && mounted) {
        setState(() {
          _errorMessage = ConsumerErrorTranslator.translate(e);
        });
      }
    }
  }

  Future<void> _generateLightningInvoice() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid positive satoshi amount');
      return;
    }

    final config = ref.read(activeNetworkConfigProvider);
    if (amount > config.maxDepositSats) {
      setState(() => _errorMessage =
          'Amount exceeds maximum deposit limit of ${config.maxDepositSats} sats for ${config.displayName}');
      return;
    }

    // Verify wallet balance cap (Fail-closed in pilot mode)
    try {
      final balance = await ref.read(cashuBalanceProvider.future);
      if (balance.totalSats + amount > config.maxWalletBalanceSats) {
        setState(() => _errorMessage =
            'Total wallet balance cannot exceed ${config.maxWalletBalanceSats} sats in ${config.displayName} (Current: ${balance.totalSats} sats [${balance.spendableSats} spendable + ${balance.lockedEscrowSats} locked], requested: $amount sats).');
        return;
      }
    } catch (_) {
      if (config.isPilot) {
        setState(() => _errorMessage =
            'Unable to verify wallet balance. Deposit disabled for safety.');
        return;
      }
    }

    setState(() {
      _isGeneratingInvoice = true;
      _errorMessage = null;
      _claimSuccessMessage = null;
      _quoteId = null;
    });

    try {
      final wallet = ref.read(cashuWalletServiceProvider);
      if (wallet == null) {
        throw StateError('Wallet not initialized');
      }

      final quote = await wallet.createMintQuote(amount);
      setState(() {
        _quoteId = quote.quoteId;
        _generatedInvoice = quote.bolt11Invoice;
        _isGeneratingInvoice = false;
      });

      _startPollingQuote(quote.quoteId);
    } catch (e) {
      setState(() {
        _errorMessage = ConsumerErrorTranslator.translate(e);
        _isGeneratingInvoice = false;
      });
    }
  }

  Future<void> _checkAndMint() async {
    if (_quoteId == null) return;
    await _checkQuoteStatusAndMint(_quoteId!, fromPolling: false);
  }

  Future<void> _claimCashuToken() async {
    final config = ref.read(activeNetworkConfigProvider);
    if (config.isPilot) {
      setState(() => _errorMessage =
          'Direct Cashu token import is disabled for the Controlled Mainnet Pilot to prevent bypassing pilot deposit limits.');
      return;
    }

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Please paste a Cashu token string');
      return;
    }

    setState(() {
      _isClaimingToken = true;
      _errorMessage = null;
      _claimSuccessMessage = null;
    });

    try {
      final wallet = ref.read(cashuWalletServiceProvider);
      if (wallet == null) {
        throw StateError('Wallet not initialized');
      }

      final received = await wallet.claimProtectedPayment(
        token: token,
        paymentId: 'deposit_${DateTime.now().millisecondsSinceEpoch}',
      );
      ref.invalidate(cashuBalanceProvider);
      ref.read(inAppNotificationProvider.notifier).show(
            title: 'Token Claimed!',
            message:
                'Successfully claimed ${Formatters.formatSats(received)} to wallet',
            icon: Icons.check_circle_outline,
            type: InAppNotificationType.success,
          );

      setState(() {
        _claimSuccessMessage = 'Successfully claimed $received sats to wallet!';
        _tokenController.clear();
        _isClaimingToken = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ConsumerErrorTranslator.translate(e);
        _isClaimingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receive & Deposit Funds',
                  style: AppTypography.titleMedium
                      .copyWith(color: colors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: colors.primary,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.bolt, size: 20), text: 'Lightning'),
              Tab(
                  icon: Icon(Icons.currency_bitcoin, size: 20),
                  text: 'On-Chain'),
              Tab(
                  icon: Icon(Icons.token_outlined, size: 20),
                  text: 'Ecash Token'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLightningTab(colors),
                _buildOnChainTab(colors),
                _buildCashuTokenTab(colors),
              ],
            ),
          ),

          // Stablecoin Deposit Prompt
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monetization_on_outlined,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Depositing USDT or USDC?',
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/receive');
                  },
                  child: const Text('Receive Stablecoins >',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightningTab(HanbovaColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mint Ecash via Lightning (NUT-04)',
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Pay this invoice with any Lightning wallet to deposit spendable ecash directly.',
            style:
                AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_generatedInvoice == null) ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (Sats)',
                hintText: 'e.g. 5000',
                suffixText: 'SATS',
                border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed:
                  _isGeneratingInvoice ? null : _generateLightningInvoice,
              icon: _isGeneratingInvoice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_2),
              label: const Text('Generate Lightning Invoice'),
            ),
          ] else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: QrImageView(
                  data: _generatedInvoice!,
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _generatedInvoice!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Lightning invoice copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Invoice'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    _generatedInvoice = null;
                    _quoteId = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _isMinting ? null : _checkAndMint,
              icon: _isMinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Check Payment & Mint Ecash'),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: colors.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildOnChainTab(HanbovaColors colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.currency_bitcoin_rounded,
                color: colors.gold, size: 36),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'On-Chain Bitcoin Swaps',
            style:
                AppTypography.titleMedium.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'On-chain Bitcoin deposits via trust-minimized swaps are under active development and disabled in this test build.',
            style:
                AppTypography.bodySmall.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Please use Lightning (NUT-04) or Ecash Tokens',
                  style: AppTypography.labelSmall
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashuTokenTab(HanbovaColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Redeem Cashu Token',
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Paste a standard cashuA / cashuB ecash token string to swap into your spendable balance.',
            style:
                AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _tokenController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'cashuB... or cashuA...',
              border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _isClaimingToken ? null : _claimCashuToken,
            icon: _isClaimingToken
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Redeem Token into Wallet'),
          ),
          if (_claimSuccessMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                borderRadius: AppRadius.smRadius,
              ),
              child: Text(
                _claimSuccessMessage!,
                style: AppTypography.bodySmall.copyWith(color: colors.success),
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: colors.error)),
          ],
        ],
      ),
    );
  }
}
