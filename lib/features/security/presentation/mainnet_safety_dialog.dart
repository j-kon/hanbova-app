import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Modal dialog informing users that Bitcoin Mainnet is safety-locked in test builds
class MainnetSafetyDialog extends ConsumerWidget {
  const MainnetSafetyDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const MainnetSafetyDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

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
            child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mainnet Safety Lock Active',
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
              'Bitcoin Mainnet is strictly disabled in this test build. All transactions use test ecash with zero monetary value.',
              style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBullet(colors, 'Production Mainnet mints are blocked by protocol safety guards.'),
            _buildBullet(colors, 'Supported environments: Local Nutshell & Cashu Testnet.'),
            _buildBullet(colors, 'Zero risk to real Bitcoin or user funds.'),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
          ),
          child: const Text('Understood'),
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
