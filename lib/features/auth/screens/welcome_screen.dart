import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Brand Icon & Identity
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Product Title
              Text(
                'Hanbova',
                style: AppTypography.display.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Tagline
              Text(
                'Send protected.',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                'Safer everyday Bitcoin payments across Africa.\nSend instantly or protect money with conditional claim windows.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Actions
              ElevatedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('Create account'),
              ),
              const SizedBox(height: AppSpacing.sm),

              OutlinedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign in'),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'By continuing, you agree to Hanbova Terms and Privacy Policy.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
