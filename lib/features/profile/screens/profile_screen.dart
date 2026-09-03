import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileProvider);
    final market = ref.watch(marketProvider);
    final residence = profile.residenceCountryInfo;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.surfaceCard,
                  colors.surfaceCard.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                // Avatar circle with initials or photo
                CircleAvatar(
                  radius: 44,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  child: Text(
                    profile.initials,
                    style: AppTypography.headline.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Full name
                Text(
                  profile.fullName,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Username handle
                Text(
                  profile.handle,
                  style: AppTypography.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                // Residence origin
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      residence.flagEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      residence.name,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/edit-profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdRadius,
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Roam Mode Highlight Tile
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  market.isRoamActive
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceCard,
                  colors.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: market.isRoamActive
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.border,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.travel_explore_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Roam Mode',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  market.isRoamActive
                      ? 'Active in ${market.spendCountryInfo.name} (${market.spendCountryInfo.flagEmoji})'
                      : 'Disabled • Using residence (${market.identityCountryInfo.flagEmoji})',
                  style: AppTypography.caption.copyWith(
                    color: market.isRoamActive
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: market.isRoamActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    market.isRoamActive ? 'ACTIVE' : 'OFF',
                    style: TextStyle(
                      color: market.isRoamActive
                          ? const Color(0xFF10B981)
                          : colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => context.push('/roam'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Management Shortcuts
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _buildTile(
                  context,
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved Payments',
                  subtitle: 'Meters, smartcards, internet accounts',
                  onTap: () => context.push('/saved-payments'),
                ),
                Divider(height: 1, color: colors.divider),
                _buildTile(
                  context,
                  icon: Icons.people_outline_rounded,
                  title: 'Beneficiaries',
                  subtitle: 'Recent & favorite contacts',
                  onTap: () => context.push('/beneficiaries'),
                ),
                Divider(height: 1, color: colors.divider),
                _buildTile(
                  context,
                  icon: Icons.credit_card_outlined,
                  title: 'Virtual Cards',
                  subtitle: 'Visa & Mastercard for online spend',
                  onTap: () => context.push('/cards'),
                ),
                Divider(height: 1, color: colors.divider),
                _buildTile(
                  context,
                  icon: Icons.shield_outlined,
                  title: 'Wallet Backup & Seed',
                  subtitle: 'Secure your recovery phrase',
                  onTap: () => context.push('/backup-seed'),
                ),
                Divider(height: 1, color: colors.divider),
                _buildTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Appearance, notifications, privacy',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Sign Out Button
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: colors.error),
                title: Text(
                  'Sign Out',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: colors.surfaceCard,
                      title: const Text('Sign Out?'),
                      content: const Text(
                        'Make sure your wallet recovery seed is safely backed up before signing out.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context.go('/auth/welcome');
                          },
                          child: Text(
                            'Sign Out',
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: colors.textPrimary),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: colors.textTertiary,
          ),
        ),
        trailing:
            Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
