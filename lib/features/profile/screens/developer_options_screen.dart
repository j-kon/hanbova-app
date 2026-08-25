import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/mint_validator.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../security/presentation/mainnet_safety_dialog.dart';
import '../../transactions/presentation/transactions_provider.dart';

class DeveloperOptionsScreen extends ConsumerStatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  ConsumerState<DeveloperOptionsScreen> createState() =>
      _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState
    extends ConsumerState<DeveloperOptionsScreen> {
  String? _mintTestResult;
  bool _isTestingMint = false;

  Future<void> _testMintSupport(String mintUrl) async {
    setState(() {
      _isTestingMint = true;
      _mintTestResult = null;
    });

    final validator = MintValidator();
    final result = await validator.validateMint(mintUrl);

    if (!mounted) return;
    setState(() {
      _isTestingMint = false;
      if (result.isValid && result.nut11Supported) {
        _mintTestResult =
            '✅ ${result.mintName}: NUT-11 Protected Payments supported';
      } else if (result.isValid && !result.nut11Supported) {
        _mintTestResult =
            '⚠️ ${result.mintName}: Mint reachable but NUT-11 (P2PK) not enabled';
      } else {
        _mintTestResult = '❌ Mint connection failed: ${result.errorMessage}';
      }
    });
  }

  void _onSelectNetwork(HanbovaNetwork selectedNet, HanbovaNetwork currentNet) {
    if (selectedNet == currentNet) return;

    if (selectedNet == HanbovaNetwork.mainnet) {
      MainnetSafetyDialog.show(context);
      return;
    }

    if (selectedNet == currentNet) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Network Environment?'),
        content: Text(
          'Switching to ${NetworkConfig.fromNetwork(selectedNet).displayName} will isolate wallet storage and switch mint endpoints.\n\nNever combine proofs from different mints.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(networkEnvironmentProvider.notifier)
                  .setNetwork(selectedNet);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Switched to ${NetworkConfig.fromNetwork(selectedNet).displayName}'),
                ),
              );
            },
            child: const Text('Switch Network'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final config = ref.watch(appConfigProvider);
    final currentNetwork = ref.watch(networkEnvironmentProvider);
    final netConfig = NetworkConfig.fromNetwork(currentNetwork);
    final authState = ref.watch(authProvider);
    final cryptoIdentity = ref.watch(cryptoIdentityProvider).value;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Developer Options'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Network Environment Card
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
                  Text('Wallet Network Environment',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Storage and Cashu proofs are strictly isolated per network.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...HanbovaNetwork.values.map((net) {
                    final cfg = NetworkConfig.fromNetwork(net);
                    final isSelected = net == currentNetwork;
                    return InkWell(
                      onTap: () => _onSelectNetwork(net, currentNetwork),
                      borderRadius: AppRadius.smRadius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? colors.primary
                                  : colors.textTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cfg.displayName,
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          color: cfg.isEnabled
                                              ? colors.textPrimary
                                              : colors.textTertiary,
                                        ),
                                      ),
                                      if (!cfg.isEnabled) ...[
                                        const SizedBox(width: AppSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Disabled',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                    color: Colors.red,
                                                    fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cfg.description,
                                    style: AppTypography.bodySmall
                                        .copyWith(color: colors.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Active Keys Card
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
                  Text('Cryptographic Client Keys',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Private keys are stored in secure on-device keychain. Only public keys are registered.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoTile(
                    label: 'Protected Payment Pubkey (secp256k1)',
                    value: cryptoIdentity?.protectedPaymentPubkey ??
                        'Generated on first protected transaction',
                  ),
                  _InfoTile(
                    label: 'Transport Encryption Pubkey (X25519)',
                    value: cryptoIdentity?.transportEncryptionPubkey ??
                        'Generated on first protected transaction',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _SectionHeader(title: 'Service Endpoints'),
            _InfoTile(label: 'API Base URL', value: config.apiBaseUrl),
            _InfoTile(
                label: 'Active Mint URL', value: netConfig.defaultMintUrl),
            _InfoTile(label: 'Storage Prefix', value: netConfig.storagePrefix),
            const SizedBox(height: AppSpacing.sm),

            OutlinedButton.icon(
              icon: _isTestingMint
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check),
              label: const Text('Verify Mint NUT-11 Support'),
              onPressed: _isTestingMint
                  ? null
                  : () => _testMintSupport(netConfig.defaultMintUrl),
            ),
            if (_mintTestResult != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _mintTestResult!,
                style: AppTypography.bodySmall.copyWith(
                  color: _mintTestResult!.startsWith('✅')
                      ? colors.primary
                      : Colors.orangeAccent,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            _SectionHeader(title: 'Cashu Protocol Support'),
            const _InfoTile(
                label: 'NUT-00 to NUT-06',
                value: 'Supported (Mint, Keysets, Tokens, Split, Melt)'),
            _SectionHeader(title: 'Presentation & Demo Controls'),
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border:
                    Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.slideshow_rounded, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Fellowship Demo Seeder',
                          style: AppTypography.titleSmall
                              .copyWith(color: colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Populate realistic African commerce transactions (Instant Lightning, Protected Escrow, Claims, and Refunds) for live pitch demos.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(transactionsProvider.notifier)
                          .seedDemoTransactions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Populated demo transactions across all 4 categories!')),
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Seed Demo Transactions'),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text:
                      'HANBOVA_DEBUG_DUMP\nAPI: ${config.apiBaseUrl}\nMint: ${netConfig.defaultMintUrl}\nNet: ${currentNetwork.name}\nUser: ${authState.user?.username ?? "anonymous"}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Debug state copied to clipboard')),
                );
              },
              child: const Text('Copy Diagnostics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall
            .copyWith(color: colors.primary, letterSpacing: 1.1),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: colors.textSecondary)),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: AppTypography.titleSmall
                .copyWith(color: colors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
