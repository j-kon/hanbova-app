import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/market/country_model.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _selectedResidenceCountry;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final market = ref.read(marketProvider);
    _selectedResidenceCountry = market.identityCountry;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Save selected country of residence
    await ref
        .read(marketProvider.notifier)
        .setIdentityCountry(_selectedResidenceCountry);

    final success = await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/wallet-setup');
    } else {
      final authState = ref.read(authProvider);
      setState(() {
        _errorMessage = authState.errorMessage ??
            'Failed to create account. Please try again.';
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
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Image.asset(
                      'assets/brand/v4/logo/hanbova_icon_v4_EXACT_MASTER_TRANSPARENT.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Text(
                  'Create an account',
                  style: AppTypography.headline
                      .copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose your Hanbova username and secure your wallet.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colors.error, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Country of Residence Picker
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedResidenceCountry,
                      isExpanded: true,
                      dropdownColor: AppColors.darkSurfaceCard,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.primary),
                      items: CountryInfo.supportedCountries.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.code,
                          child: Row(
                            children: [
                              Text(c.flagEmoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Text(
                                '${c.name} (${c.code})',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedResidenceCountry = val);
                        }
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.only(left: 4, top: 4, bottom: AppSpacing.md),
                  child: Text(
                    'Primary country of residence / compliance jurisdiction',
                    style: TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 11),
                  ),
                ),

                // Name Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'First name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Last name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Username
                TextFormField(
                  controller: _usernameController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    hintText: 'username',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Must be at least 3 characters';
                    }
                    if (v.contains(' ') ||
                        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Alphanumeric and underscores only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Email
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
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    hintText: '+234 801 234 5678',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    if (v.length < 8) {
                      return 'Must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signin'),
                      child: Text(
                        'Sign in',
                        style: AppTypography.labelMedium
                            .copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
