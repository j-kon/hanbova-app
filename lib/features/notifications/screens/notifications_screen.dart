import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _NotificationTile(
              icon: Icons.shield_outlined,
              iconColor: colors.protected,
              title: 'Protected payment active',
              message:
                  'Your payment of 25,000 sats to @amina is awaiting claim.',
              time: '2 hours ago',
              isUnread: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _NotificationTile(
              icon: Icons.bolt,
              iconColor: Colors.amber,
              title: 'Lightning settlement received',
              message: 'Received 50,000 sats from @kofi.',
              time: '1 day ago',
              isUnread: false,
            ),
            const SizedBox(height: AppSpacing.xs),
            _NotificationTile(
              icon: Icons.lock_outline,
              iconColor: colors.primary,
              title: 'Wallet security active',
              message: 'Your client-side Cashu keys are locked and encrypted.',
              time: '3 days ago',
              isUnread: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnread
            ? colors.primary.withValues(alpha: 0.05)
            : colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color:
              isUnread ? colors.primary.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.textPrimary, fontSize: 13)),
                    Text(time,
                        style: AppTypography.bodySmall.copyWith(
                            color: colors.textTertiary, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(message,
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
