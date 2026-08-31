import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/crypto/encrypted_envelope_service.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/notifications/in_app_notification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/consumer_error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../protected/data/protected_message_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../data/payment_intent_repository.dart';
import '../domain/protected_payment_intent.dart';

class ClaimPaymentScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const ClaimPaymentScreen({super.key, this.initialCode});

  @override
  ConsumerState<ClaimPaymentScreen> createState() => _ClaimPaymentScreenState();
}

class _ClaimPaymentScreenState extends ConsumerState<ClaimPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  bool _isLoading = false;
  ProtectedPaymentIntent? _loadedIntent;
  bool _isClaimed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchIntent();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final incoming = ref
            .read(transactionsProvider)
            .where((t) =>
                t.type == TransactionType.protectedClaim &&
                t.status == TransactionStatus.claimable)
            .toList();
        if (incoming.length == 1) {
          _codeController.text =
              incoming.first.claimReference ?? incoming.first.id;
          _fetchIntent();
        }
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchIntent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(paymentIntentRepositoryProvider);
      final intent =
          await repo.getPaymentIntentByReference(_codeController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadedIntent = intent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _claim() async {
    if (_loadedIntent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        throw StateError(
            'You must be authenticated to claim protected payments.');
      }

      final currentUsername = authState.user!.username.toLowerCase();
      final targetRecipient =
          _loadedIntent!.recipientIdentifier.replaceAll('@', '').toLowerCase();
      if (currentUsername != targetRecipient &&
          _loadedIntent!.recipientIdentifier != authState.user!.id) {
        throw StateError(
            'This payment is intended for @${_loadedIntent!.recipientIdentifier}, but you are logged in as @${authState.user!.username}.');
      }

      final messageService = ref.read(protectedMessageServiceProvider);
      final inbox = await messageService.getInbox();
      final matchingMsg = inbox.firstWhere(
        (m) => m.paymentIntentId == _loadedIntent!.id,
        orElse: () => throw StateError(
            'No encrypted protected envelope found for this payment intent in your inbox.'),
      );

      final cryptoService = ref.read(cryptoIdentityProvider.notifier);
      final identity = await cryptoService.requireIdentity();

      // Pre-decryption fingerprint check:
      final currentFingerprint = identity.transportKeyFingerprint;
      final recordedFingerprint = matchingMsg.recipientTransportKeyFingerprint;

      if (recordedFingerprint != null &&
          recordedFingerprint.isNotEmpty &&
          recordedFingerprint.toLowerCase() !=
              currentFingerprint.toLowerCase()) {
        throw StateError(
          'This payment was encrypted to a previous wallet identity. '
          'Your current wallet keys cannot decrypt it. Ask the sender to wait for '
          'refund availability and send a new payment to your current identity.',
        );
      }

      final envelopeService = EncryptedEnvelopeService();
      final envelope = await envelopeService.decryptEnvelope(
        ciphertextString: matchingMsg.encryptedPayload,
        recipientKeyPair: identity.transportKeyPair,
      );

      final cashuWallet = ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError(
            'Cashu wallet is not initialized. Please configure your wallet seed.');
      }

      // Execute genuine CDK NUT-11 claim
      await cashuWallet.claimProtectedPayment(
        token: envelope.cashuToken,
        paymentId: _loadedIntent!.id,
      );

      // Invalidate balance so CDK/redb is polled as sole financial truth
      ref.invalidate(cashuBalanceProvider);

      // Coordinate status with backend
      final repo = ref.read(paymentIntentRepositoryProvider);
      bool syncPending = false;
      try {
        await repo.claimPaymentIntent(_loadedIntent!.id);
      } catch (_) {
        // Backend coordination failure after mint settlement must NOT undo financial success
        syncPending = true;
      }

      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: _loadedIntent!.id,
              type: TransactionType.protectedClaim,
              status: TransactionStatus.completed,
              amountSats: _loadedIntent!.amountSats,
              recipientOrSender: _loadedIntent!.senderId ?? 'Sender',
              description:
                  _loadedIntent!.description ?? 'Claimed Protected Payment',
              createdAt: DateTime.now(),
              claimReference:
                  _loadedIntent!.claimReference ?? _loadedIntent!.id,
              coordinationSyncPending: syncPending,
              syncPendingStatus: syncPending ? 'claimed' : null,
            ),
          );

      if (!mounted) return;
      ref.read(inAppNotificationProvider.notifier).show(
            title: 'Protected payment claimed successfully.',
            message: 'Your spendable balance has been updated.',
            icon: Icons.check_circle_outline,
            type: InAppNotificationType.success,
          );
      setState(() {
        _isLoading = false;
        _isClaimed = true;
      });
    } catch (e) {
      if (!mounted) return;
      final friendlyMessage = ConsumerErrorTranslator.translate(e);
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Claim Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isClaimed
            ? _buildSuccessView()
            : _loadedIntent != null
                ? _buildIntentPreview(_loadedIntent!)
                : _buildLookupForm(),
      ),
    );
  }

  Widget _buildLookupForm() {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Claim Code',
              style: AppTypography.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter the claim code or paste the claim URL to verify and claim your protected payment.',
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(_errorMessage!,
                    style:
                        AppTypography.bodySmall.copyWith(color: colors.error)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Claim Reference or Token',
                hintText: 'hnbv_claim_...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => context.push('/scan'),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter claim code'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchIntent,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify Payment'),
            ),
            Builder(
              builder: (context) {
                final incoming = ref
                    .watch(transactionsProvider)
                    .where((t) =>
                        t.type == TransactionType.protectedClaim &&
                        t.status == TransactionStatus.claimable)
                    .toList();
                if (incoming.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Text(
                            'OR SELECT PENDING PAYMENT',
                            style: AppTypography.caption
                                .copyWith(color: colors.textTertiary),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.divider)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...incoming.map(
                      (tx) => InkWell(
                        onTap: () {
                          _codeController.text = tx.claimReference ?? tx.id;
                          _fetchIntent();
                        },
                        borderRadius: AppRadius.mdRadius,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.surfaceCard,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                                color: colors.incoming.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: colors.incoming, size: 24),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Formatters.formatSats(tx.amountSats)} from ${tx.recipientOrSender}',
                                      style: AppTypography.titleSmall
                                          .copyWith(color: colors.textPrimary),
                                    ),
                                    if (tx.description != null)
                                      Text(
                                        tx.description!,
                                        style: AppTypography.caption.copyWith(
                                            color: colors.textTertiary),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 14, color: colors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentPreview(ProtectedPaymentIntent intent) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protected Payment Found',
                    style: AppTypography.titleMedium
                        .copyWith(color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    Text(
                      Formatters.formatSats(intent.amountSats),
                      style: AppTypography.titleLarge
                          .copyWith(color: colors.primary),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(currency.format(intent.amountSats),
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textTertiary)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(color: colors.divider),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Intended Recipient',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    Text(intent.recipientIdentifier,
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.smRadius,
              ),
              child: Text(_errorMessage!,
                  style: AppTypography.bodySmall.copyWith(color: colors.error)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ElevatedButton(
            onPressed: _isLoading ? null : _claim,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Claim to Wallet Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: colors.success, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Payment Claimed!',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Protected payment claimed successfully. Your spendable balance has been updated.',
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
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
