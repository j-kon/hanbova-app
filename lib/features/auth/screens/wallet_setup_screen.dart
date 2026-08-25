import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';
import '../providers/auth_provider.dart';

class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  ConsumerState<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  int _currentStep =
      0; // 0: Init, 1: Backup Words, 2: Quiz, 3: Security, 4: Mint, 5: Fund/Done
  bool _isInitializing = true;
  String? _initError;
  List<String> _mnemonicWords = [];

  // Quiz state
  final int _quizWordIndex1 = 2; // Word #3
  final int _quizWordIndex2 = 6; // Word #7
  final int _quizWordIndex3 = 10; // Word #11
  String? _selectedWord1;
  String? _selectedWord2;
  String? _selectedWord3;
  List<String> _options1 = [];
  List<String> _options2 = [];
  List<String> _options3 = [];
  String? _quizError;

  // Biometrics
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeWallet());
  }

  Future<void> _initializeWallet() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final auth = ref.read(authProvider);
      final network = ref.read(networkEnvironmentProvider);
      final userId = auth.user?.id ?? 'default_user';

      // 1. Get or create deterministic cryptographic identity
      final identity = await ref
          .read(cryptoIdentityProvider.notifier)
          .getOrCreateIdentity(userId: userId, network: network);

      // 2. Publish public keys to backend directory
      final apiClient = ref.read(apiClientProvider);
      if (auth.accessToken != null) {
        apiClient.setAuthToken(auth.accessToken);
        try {
          await ref
              .read(cryptoIdentityProvider.notifier)
              .publishPublicKeys(apiClient: apiClient, identity: identity);
        } catch (_) {
          // Non-blocking if offline
        }
      }

      // 3. Initialize CDK wallet
      final wallet = ref.read(cashuWalletServiceProvider);
      if (wallet != null) {
        await wallet.getBalance();
      }

      final words = identity.mnemonic.split(' ');
      _prepareQuiz(words);

      if (!mounted) return;
      setState(() {
        _mnemonicWords = words;
        _isInitializing = false;
        _currentStep = 1; // Proceed to Backup Phrase
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  void _prepareQuiz(List<String> words) {
    if (words.length != 12) return;
    final random = Random();

    List<String> generateOptions(int targetIndex) {
      final target = words[targetIndex];
      final pool = words.where((w) => w != target).toList();
      pool.shuffle(random);
      final options = [target, pool[0], pool[1], pool[2]];
      options.shuffle(random);
      return options;
    }

    _options1 = generateOptions(_quizWordIndex1);
    _options2 = generateOptions(_quizWordIndex2);
    _options3 = generateOptions(_quizWordIndex3);
  }

  void _verifyQuiz() {
    final correct1 = _selectedWord1 == _mnemonicWords[_quizWordIndex1];
    final correct2 = _selectedWord2 == _mnemonicWords[_quizWordIndex2];
    final correct3 = _selectedWord3 == _mnemonicWords[_quizWordIndex3];

    if (correct1 && correct2 && correct3) {
      setState(() {
        _quizError = null;
        _currentStep = 3; // Proceed to Security
      });
    } else {
      setState(() {
        _quizError =
            'One or more selected words are incorrect. Please verify your backup.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'Initializing Wallet'
              : 'Setup Step $_currentStep of 5',
          style: AppTypography.titleSmall.copyWith(color: colors.textPrimary),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: _buildCurrentStep(colors),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(HanbovaColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildInitStep(colors);
      case 1:
        return _buildBackupPhraseStep(colors);
      case 2:
        return _buildQuizStep(colors);
      case 3:
        return _buildSecurityStep(colors);
      case 4:
        return _buildMintStep(colors);
      case 5:
      default:
        return _buildAddBitcoinStep(colors);
    }
  }

  Widget _buildInitStep(HanbovaColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isInitializing) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Initializing Secure Wallet...',
              style:
                  AppTypography.titleLarge.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Deriving deterministic P2PK and transport keys with Cashu ecash storage.',
              style: AppTypography.bodyMedium
                  .copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ] else if (_initError != null) ...[
            Icon(Icons.error_outline, color: colors.error, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Initialization Failed',
              style:
                  AppTypography.titleLarge.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _initError!,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _initializeWallet,
              child: const Text('Retry Setup'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupPhraseStep(HanbovaColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Write Down Your Recovery Phrase',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'These 12 words are the master key to your cryptographic identity and wallet. Never share them with anyone.',
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: colors.border),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _mnemonicWords.length,
              itemBuilder: (context, i) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${i + 1}.',
                        style: AppTypography.bodySmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mnemonicWords[i],
                        style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _mnemonicWords.join(' ')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Recovery phrase copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Phrase'),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text('I Have Written It Down'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStep(HanbovaColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify Recovery Backup',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please select the correct words from your 12-word recovery phrase to confirm your backup.',
            style:
                AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildQuizSelector(
            'Word #3',
            _options1,
            _selectedWord1,
            (val) => setState(() => _selectedWord1 = val),
            colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildQuizSelector(
            'Word #7',
            _options2,
            _selectedWord2,
            (val) => setState(() => _selectedWord2 = val),
            colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildQuizSelector(
            'Word #11',
            _options3,
            _selectedWord3,
            (val) => setState(() => _selectedWord3 = val),
            colors,
          ),
          if (_quizError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_quizError!,
                style: AppTypography.bodySmall.copyWith(color: colors.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: (_selectedWord1 != null &&
                    _selectedWord2 != null &&
                    _selectedWord3 != null)
                ? _verifyQuiz
                : null,
            child: const Text('Verify Backup'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSelector(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String> onSelected,
    HanbovaColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.titleSmall.copyWith(color: colors.primary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: options.map((opt) {
              final isChosen = selected == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isChosen,
                onSelected: (_) => onSelected(opt),
                selectedColor: colors.primary.withValues(alpha: 0.2),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isChosen ? colors.primary : colors.textPrimary,
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep(HanbovaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Device Security',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Protect access to your wallet and signing keys using biometric authentication (Face ID / Touch ID).',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: colors.primary, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometric Unlock',
                      style: AppTypography.titleSmall
                          .copyWith(color: colors.textPrimary),
                    ),
                    Text(
                      'Require authentication to send funds or view keys',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _biometricsEnabled,
                onChanged: (val) async {
                  if (val) {
                    final bio = ref.read(biometricServiceProvider);
                    final ok = await bio.authenticate(
                        reason: 'Enable biometric security');
                    if (ok) {
                      setState(() => _biometricsEnabled = true);
                    }
                  } else {
                    setState(() => _biometricsEnabled = false);
                  }
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 4),
          child: const Text('Continue to Mint Setup'),
        ),
      ],
    );
  }

  Widget _buildMintStep(HanbovaColors colors) {
    final network = ref.watch(networkEnvironmentProvider);
    final isPilot = ref.watch(mainnetPilotOverrideProvider);
    final config = NetworkConfig.fromNetwork(network, pilotActive: isPilot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cashu Mint Connection',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Hanbova uses ecash mints to issue genuine blinded Cashu tokens with NUT-11 cryptographic escrow.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Active Mint Connected',
                    style: AppTypography.titleSmall
                        .copyWith(color: colors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                config.defaultMintUrl,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.primary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Capabilities: NUT-04 (Minting), NUT-07 (Proof Validation), NUT-10 & NUT-11 (P2PK Spending Conditions)',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 5),
          child: const Text('Continue to Add Bitcoin'),
        ),
      ],
    );
  }

  Widget _buildAddBitcoinStep(HanbovaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.currency_bitcoin, color: colors.primary, size: 48),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Your Wallet is Ready!',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Deposit Bitcoin via Lightning to get spendable ecash, or explore the app first.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            UnifiedDepositSheet.show(context);
          },
          icon: const Icon(Icons.bolt, size: 20),
          label: const Text('Deposit Bitcoin (Lightning)'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Go to Home Screen'),
        ),
      ],
    );
  }
}
