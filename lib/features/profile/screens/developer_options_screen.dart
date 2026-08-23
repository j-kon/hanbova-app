import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DeveloperOptionsScreen extends ConsumerWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final config = ref.watch(appConfigProvider);

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
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.developer_mode, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Development Mode Active (HANBOVA_ENV=development)',
                      style: AppTypography.titleSmall.copyWith(color: colors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _SectionHeader(title: 'Service Endpoints'),
            _InfoTile(label: 'API Base URL', value: config.apiBaseUrl),
            _InfoTile(label: 'Cashu Mint URL', value: config.mintUrl),
            _InfoTile(label: 'App Environment', value: config.environment),
            const SizedBox(height: AppSpacing.md),

            _SectionHeader(title: 'Cashu Protocol Support'),
            _InfoTile(label: 'NUT-00 to NUT-06', value: 'Supported (Mint, Keysets, Tokens, Split, Melt)'),
            _InfoTile(label: 'NUT-07', value: 'Supported (Token State Check)'),
            _InfoTile(label: 'NUT-10', value: 'Supported (Spending Conditions)'),
            _InfoTile(label: 'NUT-11', value: 'Supported (P2PK & Locktime Refund)'),
            const SizedBox(height: AppSpacing.md),

            _SectionHeader(title: 'Security & Keystore'),
            _InfoTile(label: 'Keystore Provider', value: 'FlutterSecureStorage (Keychain / Keystore)'),
            _InfoTile(label: 'Wallet Key Architecture', value: 'Client-side secp256k1 (Zero Backend Custody)'),
            _InfoTile(label: 'Account Auth', value: 'Argon2id + JWT + Rotating Refresh Tokens'),
            const SizedBox(height: AppSpacing.lg),

            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'HANBOVA_DEBUG_DUMP\nAPI: ${config.apiBaseUrl}\nMint: ${config.mintUrl}\nEnv: ${config.environment}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug state copied to clipboard')),
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
        style: AppTypography.labelSmall.copyWith(color: colors.textTertiary, letterSpacing: 1),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: colors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 11),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
