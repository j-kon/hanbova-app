import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 32,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Hanbova',
                style:
                    AppTypography.display.copyWith(color: colors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Send protected.',
                style:
                    AppTypography.titleMedium.copyWith(color: colors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Africa-first Bitcoin payment application. Choose between instant settlement or protected payments with claim, expiration, and refund safeguards.',
                style: AppTypography.bodyMedium
                    .copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/welcome'),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
