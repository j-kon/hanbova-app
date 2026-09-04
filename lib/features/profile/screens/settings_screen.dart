import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/demo/demo_mode_provider.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/security/privacy_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification toggle states
  bool _notifTransactions = true;
  bool _notifProtected = true;
  bool _notifBills = true;
  bool _notifRoam = true;
  bool _notifSecurity = true;

  // Roam preference toggles
  bool _autoSuggestRoam = true;
  bool _dataSavingMode = false;
  bool _appLockEnabled = true;

  void _showAppearanceSheet(BuildContext context) {
    final colors = context.colors;
    final currentTheme = ref.read(themeControllerProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                Text(
                  'Appearance',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  title: Text('System default',
                      style: TextStyle(color: colors.textPrimary)),
                  leading: Icon(Icons.settings_suggest_outlined,
                      color: colors.textPrimary),
                  trailing: currentTheme == ThemeMode.system
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    Navigator.pop(sheetCtx);
                  },
                ),
                ListTile(
                  title: Text('Dark mode',
                      style: TextStyle(color: colors.textPrimary)),
                  leading:
                      Icon(Icons.dark_mode_outlined, color: colors.textPrimary),
                  trailing: currentTheme == ThemeMode.dark
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    Navigator.pop(sheetCtx);
                  },
                ),
                ListTile(
                  title: Text('Light mode',
                      style: TextStyle(color: colors.textPrimary)),
                  leading: Icon(Icons.light_mode_outlined,
                      color: colors.textPrimary),
                  trailing: currentTheme == ThemeMode.light
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    Navigator.pop(sheetCtx);
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
    final currentCurrency = ref.read(marketProvider).displayCurrency;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                Text(
                  'Display Currency',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...FiatCurrency.values.map((fc) {
                  final isSelected = fc == currentCurrency;
                  return ListTile(
                    title: Text('${fc.name} (${fc.code})'),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colors.primary)
                        : null,
                    onTap: () {
                      ref.read(marketProvider.notifier).setDisplayCurrency(fc);
                      Navigator.pop(sheetCtx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRoamPreferencesSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Text(
                      'Roam Preferences',
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      title: Text(
                        'Auto-suggest on Arrival',
                        style: AppTypography.bodyMedium
                            .copyWith(color: colors.textPrimary),
                      ),
                      subtitle: Text(
                        'Prompt to switch spend market when traveling',
                        style: AppTypography.caption
                            .copyWith(color: colors.textTertiary),
                      ),
                      value: _autoSuggestRoam,
                      activeThumbColor: colors.primary,
                      onChanged: (v) {
                        setState(() => _autoSuggestRoam = v);
                        setSheetState(() => _autoSuggestRoam = v);
                      },
                    ),
                    Divider(height: 1, color: colors.divider),
                    SwitchListTile(
                      title: Text(
                        'Data Saving Mode',
                        style: AppTypography.bodyMedium
                            .copyWith(color: colors.textPrimary),
                      ),
                      subtitle: Text(
                        'Reduce background refreshes while roaming',
                        style: AppTypography.caption
                            .copyWith(color: colors.textTertiary),
                      ),
                      value: _dataSavingMode,
                      activeThumbColor: colors.primary,
                      onChanged: (v) {
                        setState(() => _dataSavingMode = v);
                        setSheetState(() => _dataSavingMode = v);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWalletsAndAssetsSheet(BuildContext context) {
    final colors = context.colors;
    final demoState = ref.read(demoModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wallets & Assets',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configure supported settlement rails, custody, and regional asset access.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7931A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_bitcoin_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Bitcoin (BTC)'),
                  subtitle:
                      const Text('Lightning & Cashu bearer e-cash. Active.'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push('/money/bitcoin');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF26A17B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.attach_money_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Tether USD (USDT)'),
                  subtitle: Text(demoState.isEnabled
                      ? 'Demo stablecoin wallet. Active in Demo.'
                      : 'Multi-rail stablecoin. Provider pending.'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (demoState.isEnabled
                              ? colors.primary
                              : const Color(0xFF38BDF8))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      demoState.isEnabled ? 'Active (Demo)' : 'Coming soon',
                      style: TextStyle(
                        color: demoState.isEnabled
                            ? colors.primary
                            : const Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push('/money/usdt');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2775CA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('USD Coin (USDC)'),
                  subtitle: Text(demoState.isEnabled
                      ? 'Demo stablecoin wallet. Active in Demo.'
                      : 'Regulated digital dollar. Provider pending.'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (demoState.isEnabled
                              ? colors.primary
                              : const Color(0xFF38BDF8))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      demoState.isEnabled ? 'Active (Demo)' : 'Coming soon',
                      style: TextStyle(
                        color: demoState.isEnabled
                            ? colors.primary
                            : const Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push('/money/usdc');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpModal(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Help & Support',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Have questions or need assistance with your payments, Roam Mode, or backup?',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Icon(Icons.article_outlined, color: colors.primary),
                  title: const Text('Documentation & FAQ'),
                  subtitle: const Text(
                      'Read guides on non-custodial Cashu & payments'),
                  onTap: () => Navigator.pop(sheetCtx),
                ),
                ListTile(
                  leading:
                      Icon(Icons.chat_bubble_outline, color: colors.primary),
                  title: const Text('Community Discord'),
                  subtitle: const Text('Join the Hanbova community'),
                  onTap: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _developerTapCount = 0;

  void _showAboutModal(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'H',
                        style: AppTypography.headline.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'Hanbova App',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: kDebugMode
                        ? () {
                            _developerTapCount++;
                            if (_developerTapCount >= 7) {
                              _developerTapCount = 0;
                              Navigator.pop(sheetCtx);
                              context.push('/developer-options');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Developer Options Unlocked! 🛠️'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } else if (_developerTapCount >= 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'You are ${7 - _developerTapCount} steps away from Developer Options.',
                                  ),
                                  duration: const Duration(milliseconds: 600),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Version 1.2.0 • Brand V4',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Non-custodial Cashu & Bitcoin wallet built for African borders, everyday spend, and pan-African travel.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final privacy = ref.watch(privacyProvider);
    final market = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          // 1. General Section
          _buildSectionHeader(context, 'GENERAL'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme & dark mode',
                onTap: () => _showAppearanceSheet(context),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {},
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.monetization_on_outlined,
                title: 'Display Currency',
                subtitle: market.displayCurrency.code,
                onTap: () => _showCurrencySheet(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Payments Section
          _buildSectionHeader(context, 'PAYMENTS'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.bookmark_border_rounded,
                title: 'Saved Payments',
                subtitle: 'Meters, smartcards, internet IDs',
                onTap: () => context.push('/saved-payments'),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.people_outline_rounded,
                title: 'Beneficiaries',
                subtitle: 'Frequent recipients & accounts',
                onTap: () => context.push('/beneficiaries'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Roam Section
          _buildSectionHeader(context, 'ROAM'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.travel_explore_rounded,
                title: 'Roam Mode',
                subtitle: market.isRoamActive
                    ? 'Active (${market.spendCountryInfo.flagEmoji} ${market.spendCountryInfo.name})'
                    : 'Off',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: market.isRoamActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : colors.textTertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    market.isRoamActive ? 'Active' : 'Off',
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
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.tune_rounded,
                title: 'Roam Preferences',
                subtitle: 'Auto-suggest on arrival & data saving',
                onTap: () => _showRoamPreferencesSheet(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Notifications Section
          _buildSectionHeader(context, 'NOTIFICATIONS'),
          _buildSettingsCard(
            context,
            children: [
              SwitchListTile(
                title: Text('Transaction Alerts',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Incoming and completed payments',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _notifTransactions,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _notifTransactions = v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Protected Payment Alerts',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Claim reminders and expiration alerts',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _notifProtected,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _notifProtected = v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Bills & Tokens',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Electricity tokens and TV renewal notices',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _notifBills,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _notifBills = v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Roam & eSIM Alerts',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Low data balance and destination tips',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _notifRoam,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _notifRoam = v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Security Notices',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Critical backup and authentication alerts',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _notifSecurity,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _notifSecurity = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. Privacy & Security Section
          _buildSectionHeader(context, 'PRIVACY & SECURITY'),
          _buildSettingsCard(
            context,
            children: [
              SwitchListTile(
                title: Text('Hide Balances',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Mask monetary amounts on home and widgets',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: privacy.isBalanceHidden,
                activeThumbColor: colors.primary,
                onChanged: (v) =>
                    ref.read(privacyProvider.notifier).setBalanceHidden(v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Hide Notification Amounts',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Hide sats/fiat in push notifications',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: privacy.hideNotificationAmounts,
                activeThumbColor: colors.primary,
                onChanged: (v) => ref
                    .read(privacyProvider.notifier)
                    .setHideNotificationAmounts(v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('Biometrics for Sensitive Actions',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Require Face ID / Touch ID before sending',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: privacy.requireBiometricForSensitive,
                activeThumbColor: colors.primary,
                onChanged: (v) => ref
                    .read(privacyProvider.notifier)
                    .setRequireBiometricForSensitive(v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('App Lock',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Require Face ID / PIN on launch',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: _appLockEnabled,
                activeThumbColor: colors.primary,
                onChanged: (v) => setState(() => _appLockEnabled = v),
              ),
              _buildDivider(context),
              SwitchListTile(
                title: Text('App Switcher Privacy',
                    style: AppTypography.bodyMedium
                        .copyWith(color: colors.textPrimary)),
                subtitle: Text('Blur app content in multitasking switcher',
                    style: AppTypography.caption
                        .copyWith(color: colors.textTertiary)),
                value: privacy.hideInAppSwitcher,
                activeThumbColor: colors.primary,
                onChanged: (v) =>
                    ref.read(privacyProvider.notifier).setHideInAppSwitcher(v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 6. Wallet Section
          _buildSectionHeader(context, 'WALLET'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallets & Assets',
                subtitle: 'Bitcoin, USDT, USDC configuration',
                onTap: () => _showWalletsAndAssetsSheet(context),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.shield_outlined,
                title: 'Backup Seed',
                subtitle: '12-word recovery phrase',
                onTap: () => context.push('/backup-seed'),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.restore_rounded,
                title: 'Recovery',
                subtitle: 'Restore wallet from backup phrase',
                onTap: () => context.push('/restore-seed'),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.dns_outlined,
                title: 'Wallet Information & Mints',
                subtitle: 'Connected Cashu mints & ecash balances',
                onTap: () => context.push('/mints'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 7. Support Section
          _buildSectionHeader(context, 'SUPPORT'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                subtitle: 'Guides and FAQs',
                onTap: () => _showHelpModal(context),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.report_problem_outlined,
                title: 'Report a Problem',
                subtitle: 'Send feedback or bug reports',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback form opened.')),
                  );
                },
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'About Hanbova',
                subtitle: 'Version 1.2.0',
                onTap: () => _showAboutModal(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mdRadius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return ListTile(
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
      trailing: trailing ??
          Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colors = context.colors;
    return Divider(height: 1, color: colors.divider);
  }
}
