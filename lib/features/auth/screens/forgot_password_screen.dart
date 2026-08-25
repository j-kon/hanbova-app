import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  String? _devToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ref
          .read(authProvider.notifier)
          .forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
        _devToken = res['dev_reset_token'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Forgot password?',
                style:
                    AppTypography.headline.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the email associated with your Hanbova account to reset your password.',
                style: AppTypography.bodyMedium
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: colors.success),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Check your email',
                            style: AppTypography.titleSmall
                                .copyWith(color: colors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'If an account matches ${_emailController.text}, a password reset link has been dispatched.',
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_devToken != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Developer Reset Token (Development Mode)',
                          style: AppTypography.labelMedium
                              .copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SelectableText(
                          _devToken!,
                          style: AppTypography.bodySmall
                              .copyWith(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: () =>
                              context.push('/reset-password?token=$_devToken'),
                          child: const Text('Proceed to Reset Password'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to sign in'),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'you@example.com',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
