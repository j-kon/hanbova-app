import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/market/country_model.dart';
import '../../../core/market/market_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKeyStep0 = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countrySearchController = TextEditingController();

  int _currentStep =
      0; // 0: Name, 1: Email & Password, 2: Country of Residence, 3: Country Confirmation
  late String _selectedResidenceCountry;
  String _countrySearchQuery = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final market = ref.read(marketProvider);
    _selectedResidenceCountry = market.residenceCountry;
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
    _countrySearchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _errorMessage = null);
    if (_currentStep == 0) {
      if (!_formKeyStep0.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKeyStep1.currentState!.validate()) return;
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    setState(() => _errorMessage = null);
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _onCountrySelected(String code) {
    setState(() {
      _selectedResidenceCountry = code;
      _currentStep = 3; // Advance to confirmation explanation
    });
  }

  Future<void> _handleCompleteSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Persist Country of Residence in MarketNotifier
    await ref
        .read(marketProvider.notifier)
        .setResidenceCountry(_selectedResidenceCountry);

    // 2. Perform Account Registration
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
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepDot(0),
            const SizedBox(width: 6),
            _buildStepDot(1),
            const SizedBox(width: 6),
            _buildStepDot(2),
            const SizedBox(width: 6),
            _buildStepDot(3),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: colors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.error, size: 20),
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
              ],
              Expanded(
                child: _buildCurrentStepContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int stepIndex) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;
    return Container(
      width: isCurrent ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.darkBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Name(context);
      case 1:
        return _buildStep1Email(context);
      case 2:
        return _buildStep2Country(context);
      case 3:
      default:
        return _buildStep3Confirmation(context);
    }
  }

  // STEP 0: First Name + Last Name (and Username)
  Widget _buildStep0Name(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Form(
        key: _formKeyStep0,
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
              style: AppTypography.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your first and last name to get started.',
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // First Name
            TextFormField(
              key: const Key('firstNameField'),
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Last Name
            TextFormField(
              key: const Key('lastNameField'),
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Username
            TextFormField(
              key: const Key('usernameField'),
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
                  return 'Only letters, numbers, and underscores';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius),
              ),
              child: Text(
                'Continue',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Email + Password
  Widget _buildStep1Email(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account credentials',
              style: AppTypography.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your email address and choose a secure password.',
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Email
            TextFormField(
              key: const Key('emailField'),
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
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Password
            TextFormField(
              key: const Key('passwordField'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm Password
            TextFormField(
              key: const Key('confirmPasswordField'),
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
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius),
              ),
              child: Text(
                'Continue to Country Selection',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Country of Residence Selection (Global, Searchable)
  Widget _buildStep2Country(BuildContext context) {
    final colors = context.colors;
    final filteredCountries = CountryInfo.search(_countrySearchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where do you live?',
          style: AppTypography.headline.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose your country of residence.\nThis helps Hanbova personalize your wallet\nand show services available where you live.',
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: TextField(
            key: const Key('countrySearchField'),
            controller: _countrySearchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search countries',
              hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              suffixIcon: _countrySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _countrySearchController.clear();
                        setState(() => _countrySearchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _countrySearchQuery = val),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Country List
        Expanded(
          child: filteredCountries.isEmpty
              ? Center(
                  child: Text(
                    'No countries found for "$_countrySearchQuery"',
                    style: const TextStyle(color: AppColors.darkTextSecondary),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredCountries.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.darkBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = filteredCountries[index];
                    final isSelected = c.code == _selectedResidenceCountry;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      leading: Text(
                        c.flagEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${c.code} • ${c.defaultCurrency.code}',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : const Icon(Icons.chevron_right_rounded,
                              color: AppColors.darkTextTertiary),
                      onTap: () => _onCountrySelected(c.code),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // STEP 3: Post-Country Explanation Confirmation
  Widget _buildStep3Confirmation(BuildContext context) {
    final colors = context.colors;
    final country = CountryInfo.findByCode(_selectedResidenceCountry);
    final isSupportedMarket =
        CountryInfo.isSupportedLocalMarket(_selectedResidenceCountry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                country.flagEmoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Hanbova in ${country.name}',
          style: AppTypography.headline.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Country of residence: ${country.name} (${country.code})',
          style: AppTypography.caption.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSupportedMarket) ...[
                _buildFeatureRow(
                    context,
                    Icons.currency_bitcoin,
                    'Bitcoin wallet',
                    'Instant Lightning & on-chain settlement'),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    context,
                    Icons.shield_outlined,
                    'Protected payments',
                    'Escrow, locktime, and claim safeguards'),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    context,
                    Icons.flash_on_rounded,
                    'Everyday payments',
                    'Airtime, data, electricity, and local bills'),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    context,
                    Icons.storefront_outlined,
                    'Local services',
                    'Domestic bank payouts & operator integrations'),
              ] else ...[
                _buildFeatureRow(
                    context,
                    Icons.currency_bitcoin,
                    'Bitcoin wallet',
                    'Instant Lightning & on-chain settlement'),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    context,
                    Icons.shield_outlined,
                    'Protected payments',
                    'Escrow, locktime, and claim safeguards'),
                const SizedBox(height: 12),
                _buildFeatureRow(context, Icons.swap_horiz_rounded,
                    'Send and receive', 'Global cross-border payments in sats'),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    context,
                    Icons.flight_takeoff_rounded,
                    'Activate Roam',
                    'Available when traveling to supported markets'),
              ],
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCompleteSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: AppColors.charcoal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  'Continue to Wallet Setup',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildFeatureRow(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
