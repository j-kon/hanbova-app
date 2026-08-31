import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/protected_payment_intent.dart';
import 'protected_send_provider.dart';

class ProtectedSendScreen extends ConsumerStatefulWidget {
  const ProtectedSendScreen({super.key});

  @override
  ConsumerState<ProtectedSendScreen> createState() =>
      _ProtectedSendScreenState();
}

class _ProtectedSendScreenState extends ConsumerState<ProtectedSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedExpirationSeconds = 86400; // 24h default
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _expirationOptions = [
    {'label': '30s (Dev)', 'seconds': 30},
    {'label': '60s (Dev)', 'seconds': 60},
    {'label': '1 hour', 'seconds': 3600},
    {'label': '6 hours', 'seconds': 21600},
    {'label': '1 day (24h)', 'seconds': 86400},
    {'label': '3 days', 'seconds': 259200},
    {'label': '7 days', 'seconds': 604800},
  ];

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amountSats = int.parse(_amountController.text.trim());
    final recipient = _recipientController.text.trim();
    final description = _descriptionController.text.trim();

    final network = ref.read(networkEnvironmentProvider);
    final isPilot = ref.read(mainnetPilotOverrideProvider);
    final config = NetworkConfig.fromNetwork(network, pilotActive: isPilot);
    if (amountSats > config.maxSendSats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount exceeds maximum send limit of ${config.maxSendSats} sats for ${config.displayName}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(protectedSendProvider.notifier).createProtectedPayment(
            amountSats: amountSats,
            recipientIdentifier: recipient,
            description: description,
            expirationSeconds: _selectedExpirationSeconds,
          );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(protectedSendProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Protected Send'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(protectedSendProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: state.createdIntent != null
            ? _buildSuccessReceipt(state.createdIntent!)
            : _buildForm(state),
      ),
    );
  }

  Widget _buildForm(ProtectedSendState state) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);
    final currentSats = int.tryParse(_amountController.text.trim()) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.protected.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
                border:
                    Border.all(color: colors.protected.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: colors.protected, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Funds are locked in Cashu P2PK escrow. After the protection window ends, Refund becomes available. Until either claim or refund is accepted by the mint, the payment may still be claimable by the recipient.',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recipient
            TextFormField(
              controller: _recipientController,
              decoration: InputDecoration(
                labelText: 'Recipient',
                hintText: '@username, phone, or email',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => context.push('/scan'),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please specify recipient';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Amount (sats)',
                hintText: 'e.g. 25000',
                suffixText: currency.format(currentSats),
                prefixIcon: const Icon(Icons.currency_bitcoin_rounded),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter amount';
                }
                final num = int.tryParse(val.trim());
                if (num == null || num <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Milestone 1 delivery',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Protection Period
            Text(
              'Protection Window (Locktime)',
              style:
                  AppTypography.titleSmall.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _expirationOptions.map((opt) {
                  final isSelected =
                      _selectedExpirationSeconds == opt['seconds'];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(opt['label'] as String),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      backgroundColor: colors.surfaceElevated,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.charcoal
                            : colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() =>
                          _selectedExpirationSeconds = opt['seconds'] as int),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.errorMessage!.contains('access token')
                          ? 'Your session has expired. Please sign in again to continue.'
                          : state.errorMessage!,
                      style:
                          AppTypography.bodySmall.copyWith(color: colors.error),
                    ),
                    if (state.errorMessage!.contains('access token')) ...[
                      const SizedBox(height: AppSpacing.xs),
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.login, size: 16),
                        label: const Text('Sign In Again'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            ElevatedButton.icon(
              onPressed: (state.isLoading || _isSubmitting) ? null : _submit,
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: (state.isLoading || _isSubmitting)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lock & Send Protected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessReceipt(ProtectedPaymentIntent intent) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.protected.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined,
                  color: colors.protected, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Protected Payment Created!',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Funds are locked in Cashu P2PK escrow.',
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    Text(
                      Formatters.formatSats(intent.amountSats),
                      style: AppTypography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    currency.format(intent.amountSats),
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textTertiary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(color: colors.divider),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recipient',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        intent.recipientIdentifier,
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.textPrimary),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Claim Code',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary)),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              intent.claimReference ?? 'N/A',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.primary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (intent.claimReference != null &&
                              intent.claimReference!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: intent.claimReference!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Claim code copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Icon(Icons.copy,
                                  size: 14, color: colors.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (intent.expiresAt != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expires At',
                          style: AppTypography.bodySmall
                              .copyWith(color: colors.textSecondary)),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          Formatters.formatDate(intent.expiresAt!),
                          style: AppTypography.bodySmall
                              .copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              ref.read(protectedSendProvider.notifier).reset();
              context.go('/home');
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
