import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/security/wallet_backup_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricsEnabled = true;

  void _showAppearanceSheet(BuildContext context) {
    final colors = context.colors;
    final currentTheme = ref.read(themeControllerProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: AppSpacing.md),
                Text('Appearance',
                    style: AppTypography.titleMedium
                        .copyWith(color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  title: const Text('System default'),
                  leading: const Icon(Icons.settings_suggest_outlined),
                  trailing: currentTheme == ThemeMode.system
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Dark mode'),
                  leading: const Icon(Icons.dark_mode_outlined),
                  trailing: currentTheme == ThemeMode.dark
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Light mode'),
                  leading: const Icon(Icons.light_mode_outlined),
                  trailing: currentTheme == ThemeMode.light
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencySheet(BuildContext context) {
    final colors = context.colors;
    final currentCurrency = ref.read(currencyProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: AppSpacing.md),
                  Text('Display Currency',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: FiatCurrency.values.map((c) {
                        final isSelected = c == currentCurrency;
                        return ListTile(
                          title: Text('${c.code} (${c.symbol})'),
                          trailing: isSelected
                              ? Icon(Icons.check, color: colors.primary)
                              : null,
                          onTap: () {
                            ref.read(currencyProvider.notifier).setCurrency(c);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        title: const Text('Hanbova Support & Help',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with your wallet, payments, or travel roaming?',
              style:
                  TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('support@hanbova.com',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Community: @hanbova_help',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your client-side wallet keys remain securely saved on this device. You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/welcome');
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final isDev = ref.watch(appConfigProvider).isDevelopment;
    final currentTheme = ref.watch(themeControllerProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final market = ref.watch(marketProvider);
    final isBackedUp =
        ref.watch(walletBackupStatusProvider).valueOrNull ?? false;

    final displayName =
        user?.displayName.isNotEmpty == true ? user!.displayName : 'Jeremiah';
    final handle = user?.handle.isNotEmpty == true ? user!.handle : '@jeremiah';
    final email =
        user?.email.isNotEmpty == true ? user!.email : 'jeremiah@example.com';

    String themeLabel;
    switch (currentTheme) {
      case ThemeMode.system:
        themeLabel = 'System';
        break;
      case ThemeMode.dark:
        themeLabel = 'Dark';
        break;
      case ThemeMode.light:
        themeLabel = 'Light';
        break;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Me & Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primary.withValues(alpha: 0.15),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'J',
                      style: AppTypography.headline
                          .copyWith(color: colors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.titleMedium
                                  .copyWith(color: colors.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                color: colors.primary, size: 16),
                          ],
                        ),
                        Text(handle,
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.primary)),
                        Text(email,
                            style: AppTypography.bodySmall.copyWith(
                                color: colors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Residence vs Travel Market Indicator
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Text(market.identityCountryInfo.flagEmoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Residence: ${market.identityCountryInfo.name} (${market.identityCountry})',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Active Travel Spend: ${market.spendCountryInfo.name} (${market.spendCountry})',
                          style: const TextStyle(
                              color: AppColors.darkTextSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Security Section
            _SectionTitle(title: 'Security & Backup'),
            _SettingTile(
              icon: Icons.key_rounded,
              title: 'Recovery Phrase Backup',
              subtitle: '12-word recovery phrase for client-side wallet',
              trailing: isBackedUp
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Backed up',
                          style: AppTypography.labelSmall
                              .copyWith(color: colors.success)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Needs Backup',
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.amber)),
                    ),
              onTap: () => context.push('/backup-seed'),
            ),
            _SettingTile(
              icon: Icons.fingerprint,
              title: 'Biometric Login / Face ID',
              trailing: Switch.adaptive(
                value: _biometricsEnabled,
                activeTrackColor: colors.primary,
                onChanged: (val) => setState(() => _biometricsEnabled = val),
              ),
            ),
            _SettingTile(
              icon: Icons.account_balance_rounded,
              title: 'Connected Ecash Mints',
              subtitle: 'Multi-mint liquidity & settlement connections',
              trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
              onTap: () => context.push('/mints'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Preferences Section
            _SectionTitle(title: 'Preferences'),
            _SettingTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              trailing: Text(themeLabel,
                  style:
                      AppTypography.bodySmall.copyWith(color: colors.primary)),
              onTap: () => _showAppearanceSheet(context),
            ),
            _SettingTile(
              icon: Icons.currency_exchange,
              title: 'Display Currency',
              trailing: Text(currentCurrency.code,
                  style:
                      AppTypography.bodySmall.copyWith(color: colors.primary)),
              onTap: () => _showCurrencySheet(context),
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Support & Help Center',
              trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
              onTap: () => _showSupportDialog(context),
            ),
            const SizedBox(height: AppSpacing.md),

            // Developer Section (Hidden in Production, visible only in debug/development mode)
            if (kDebugMode && isDev) ...[
              _SectionTitle(title: 'Developer Diagnostics'),
              _SettingTile(
                icon: Icons.developer_mode,
                title: 'Developer Options',
                subtitle: 'Cashu Mint URLs, Keys, Diagnostics',
                trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
                onTap: () => context.push('/developer-options'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Sign out Button
            OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: Icon(Icons.logout, color: colors.error, size: 18),
              label: Text('Sign out', style: TextStyle(color: colors.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Brand Footer
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/brand/v4/logo/hanbova_icon_v4_EXACT_MASTER_TRANSPARENT.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hanbova',
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Send protected. • v0.5.0-beta',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall
            .copyWith(color: colors.textTertiary, letterSpacing: 0.8),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.smRadius,
        child: ListTile(
          leading: Icon(icon, color: colors.textSecondary, size: 22),
          title: Text(title,
              style: AppTypography.titleSmall
                  .copyWith(color: colors.textPrimary, fontSize: 14)),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: AppTypography.bodySmall
                      .copyWith(color: colors.textTertiary, fontSize: 11))
              : null,
          trailing: trailing,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 2),
        ),
      ),
    );
  }
}
