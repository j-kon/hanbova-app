import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          children: [
            _SectionHeader(title: 'Network & Backend'),
            _SettingsTile(
              icon: Icons.dns_outlined,
              title: 'API Endpoint',
              subtitle: config.apiBaseUrl,
            ),
            _SettingsTile(
              icon: Icons.electric_bolt_outlined,
              title: 'Lightning Engine',
              subtitle: 'Breez SDK / Development Adapter',
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Protected Protocol',
              subtitle: 'Cashu P2PK / Timelocked Escrow Adapter',
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(title: 'Security & Keys'),
            _SettingsTile(
              icon: Icons.key_rounded,
              title: 'Local Keystore',
              subtitle: 'Hardware-backed Encrypted Storage',
            ),
            _SettingsTile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Confirmation',
              subtitle: 'Enabled for Protected Sends',
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(title: 'About'),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Hanbova Version',
              subtitle: '${config.appVersion} (Alpha)',
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Open Source License',
              subtitle: 'MIT License',
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
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: colors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.xsRadius,
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          title: Text(
            title,
            style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
