import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'backup_seed_screen.dart';

/// Modal dialog presented before enabling Bitcoin Mainnet
class MainnetSafetyDialog extends ConsumerStatefulWidget {
  const MainnetSafetyDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MainnetSafetyDialog(),
    );
  }

  @override
  ConsumerState<MainnetSafetyDialog> createState() => _MainnetSafetyDialogState();
}

class _MainnetSafetyDialogState extends ConsumerState<MainnetSafetyDialog> {
  bool _confirmedRisk = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBackedUp = ref.watch(walletBackupStatusProvider);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgRadius,
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: AppRadius.smRadius,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Switch to Mainnet',
              style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You are switching to Bitcoin Mainnet. On Mainnet:',
              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBullet(colors, 'Payments use real Bitcoin and ecash with monetary value.'),
            _buildBullet(colors, 'Settled instant and claimed escrow transactions are final.'),
            _buildBullet(colors, 'You are the sole custodian of your private keys and ecash proofs.'),
            const SizedBox(height: AppSpacing.md),

            // Backup Status Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: (isBackedUp ? colors.success : Colors.redAccent).withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: (isBackedUp ? colors.success : Colors.redAccent).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBackedUp ? Icons.check_circle_outline : Icons.error_outline,
                    color: isBackedUp ? colors.success : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isBackedUp
                          ? 'Recovery phrase verified'
                          : 'Seed phrase backup recommended before Mainnet',
                      style: AppTypography.caption.copyWith(
                        color: isBackedUp ? colors.success : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isBackedUp) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () {
                  context.pop(false);
                  context.push('/security/backup');
                },
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Back up Recovery Phrase now'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Acknowledgment Checkbox
            InkWell(
              onTap: () => setState(() => _confirmedRisk = !_confirmedRisk),
              borderRadius: AppRadius.smRadius,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _confirmedRisk,
                    onChanged: (val) => setState(() => _confirmedRisk = val ?? false),
                    activeColor: colors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I understand that Mainnet payments are real and non-reversible.',
                      style: AppTypography.caption.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _confirmedRisk
              ? () {
                  ref.read(networkEnvironmentProvider.notifier).setNetwork(HanbovaNetwork.mainnet);
                  context.pop(true);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
          ),
          child: const Text('Enable Mainnet', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBullet(HanbovaColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTypography.bodySmall.copyWith(color: Colors.amber)),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
