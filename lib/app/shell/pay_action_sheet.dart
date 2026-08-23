import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PayActionSheet extends StatelessWidget {
  const PayActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PayActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(color: colors.border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'What would you like to do?',
              style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. Send Instant
            _ActionTile(
              icon: Icons.bolt,
              iconColor: Colors.amber,
              title: 'Send Instant',
              subtitle: 'Pay immediately via Lightning invoice or handle',
              badge: 'Final Immediately',
              badgeColor: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                context.push('/send');
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 2. Send Protected
            _ActionTile(
              icon: Icons.shield_outlined,
              iconColor: colors.protected,
              title: 'Send Protected',
              subtitle: 'Send with timelock claim & self-service refund',
              badge: 'Protected Escrow',
              badgeColor: colors.protected,
              onTap: () {
                Navigator.pop(context);
                context.push('/protected-send');
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Receive Bitcoin
            _ActionTile(
              icon: Icons.arrow_downward,
              iconColor: colors.incoming,
              title: 'Receive Bitcoin',
              subtitle: 'Show QR code or payment request invoice',
              onTap: () {
                Navigator.pop(context);
                context.push('/receive');
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 4. Scan
            _ActionTile(
              icon: Icons.qr_code_scanner,
              iconColor: colors.textPrimary,
              title: 'Scan',
              subtitle: 'Scan QR code or Hanbova claim link',
              onTap: () {
                Navigator.pop(context);
                context.push('/scan');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceElevated,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? colors.primary).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: AppTypography.labelSmall.copyWith(
                                color: badgeColor ?? colors.primary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
