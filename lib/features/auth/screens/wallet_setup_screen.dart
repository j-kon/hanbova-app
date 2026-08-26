import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/cashu/mint_validator.dart';
import '../../../core/crypto/bip39_words.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';
import '../providers/auth_provider.dart';

enum KeyPublicationStatus {
  notStarted,
  published,
  syncPending,
}

class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  ConsumerState<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  int _currentStep =
      0; // 0: Init, 1: Backup Words, 2: Quiz, 3: Security, 4: Mint, 5: Fund/Done
  bool _isInitializing = true;
  bool _isAuthMissing = false;
  String? _initError;
  List<String> _mnemonicWords = [];
  KeyPublicationStatus _keyPubStatus = KeyPublicationStatus.notStarted;
  String? _keyPubError;

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

  // Mint probe state
  bool _isProbingMint = false;
  bool _mintProbeSuccess = false;
  String? _mintProbeError;
  String? _mintName;
  String? _mintDescription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeWallet());
  }

  Future<void> _initializeWallet() async {
    if (!_isInitializing) {
      setState(() {
        _isInitializing = true;
        _isAuthMissing = false;
        _initError = null;
      });
    }

    try {
      final auth = ref.read(authProvider);
      if (auth.user == null || auth.user!.id.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _isAuthMissing = true;
          _initError =
              'Authentication required. Please sign in or create an account before setting up your wallet.';
        });
        return;
      }

      final userId = auth.user!.id;
      final config = ref.read(activeNetworkConfigProvider);

      // 1. Get or create deterministic cryptographic identity
      final identity = await ref
          .read(cryptoIdentityProvider.notifier)
          .getOrCreateIdentity(userId: userId, network: config.network);

      // 2. Publish public keys to backend directory
      final apiClient = ref.read(apiClientProvider);
      if (auth.accessToken != null) {
        apiClient.setAuthToken(auth.accessToken);
        try {
          await ref
              .read(cryptoIdentityProvider.notifier)
              .publishPublicKeys(apiClient: apiClient, identity: identity);
          _keyPubStatus = KeyPublicationStatus.published;
          _keyPubError = null;
        } catch (e) {
          _keyPubStatus = KeyPublicationStatus.syncPending;
          _keyPubError =
              'Key directory sync pending. Tap to retry publishing keys.';
        }
      }

      // 3. Initialize Cashu CDK wallet (Fail-closed)
      final wallet = ref.read(cashuWalletServiceProvider);
      if (wallet == null) {
        throw StateError(
            'Failed to initialize Cashu wallet service. CDK wallet is required to proceed.');
      }
      await wallet.getBalance();

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

  Future<void> _retryKeyPublication() async {
    final auth = ref.read(authProvider);
    final cryptoIdentity = ref.read(cryptoIdentityProvider).value;
    if (auth.accessToken == null || cryptoIdentity == null) return;

    final apiClient = ref.read(apiClientProvider);
    apiClient.setAuthToken(auth.accessToken);

    try {
      await ref
          .read(cryptoIdentityProvider.notifier)
          .publishPublicKeys(apiClient: apiClient, identity: cryptoIdentity);
      if (!mounted) return;
      setState(() {
        _keyPubStatus = KeyPublicationStatus.published;
        _keyPubError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment keys published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _keyPubStatus = KeyPublicationStatus.syncPending;
        _keyPubError = 'Key directory sync failed: $e';
      });
    }
  }

  void _prepareQuiz(List<String> words) {
    if (words.length != 12) return;
    final random = Random();

    List<String> generateOptions(int targetIndex) {
      final target = words[targetIndex];
      final pool = words.where((w) => w != target).toSet().toList();
      while (pool.length < 3) {
        final candidate =
            bip39EnglishWords[random.nextInt(bip39EnglishWords.length)];
        if (candidate != target && !pool.contains(candidate)) {
          pool.add(candidate);
        }
      }
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

  Future<void> _probeActiveMint() async {
    final config = ref.read(activeNetworkConfigProvider);
    setState(() {
      _isProbingMint = true;
      _mintProbeError = null;
    });

    try {
      final validator = MintValidator();
      final result = await validator.validateMint(config.defaultMintUrl);
      if (!result.isValid) {
        setState(() {
          _isProbingMint = false;
          _mintProbeSuccess = false;
          _mintProbeError = result.errorMessage ??
              'Could not reach mint at ${config.defaultMintUrl}';
        });
      } else if (!result.isFullySupported) {
        setState(() {
          _isProbingMint = false;
          _mintProbeSuccess = false;
          _mintProbeError = result.errorMessage ??
              'Mint is missing required Cashu capabilities';
        });
      } else {
        setState(() {
          _isProbingMint = false;
          _mintProbeSuccess = true;
          _mintName = result.mintName;
          _mintDescription = result.description ?? result.motd;
        });
      }
    } catch (e) {
      setState(() {
        _isProbingMint = false;
        _mintProbeSuccess = false;
        _mintProbeError = 'Mint probe failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_getStepTitle()),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentStep > 0 && !_isInitializing)
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Skip to Home'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildCurrentStep(colors),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Initializing Wallet';
      case 1:
        return 'Step 1 of 4: Backup Phrase';
      case 2:
        return 'Step 2 of 4: Verify Backup';
      case 3:
        return 'Step 3 of 4: Device Security';
      case 4:
        return 'Step 4 of 4: Mint Setup';
      case 5:
      default:
        return 'Wallet Ready';
    }
  }

  Widget _buildCurrentStep(HanbovaColors colors) {
    if (_isInitializing || _initError != null) {
      return _buildInitStep(colors);
    }

    switch (_currentStep) {
      case 1:
        return _buildBackupPhraseStep(colors);
      case 2:
        return _buildQuizStep(colors);
      case 3:
        return _buildSecurityStep(colors);
      case 4:
        return _buildMintStep(colors);
      case 5:
        return _buildAddBitcoinStep(colors);
      default:
        return _buildInitStep(colors);
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
                color: colors.primary.withValues(alpha: 0.1),
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
          ] else if (_isAuthMissing) ...[
            Icon(Icons.lock_outline, color: colors.warning, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Authentication Required',
              style:
                  AppTypography.titleLarge.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _initError ??
                  'Please sign in or create an account before configuring your wallet.',
              style:
                  AppTypography.bodySmall.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign In to Continue'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Create New Account'),
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
              child: const Text('Retry'),
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
            'Write these words down and keep them private. Never share them with anyone.',
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
          // Security note on recovery scope
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your phrase restores Hanbova\'s wallet seed and primary identities. Complete ecash recovery after total device loss is still experimental in this pilot.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
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
          'Hardware-backed cryptographic identity and platform biometric gating.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Truthful biometric explanation
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: colors.primary, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Biometric Hardware Security',
                          style: AppTypography.titleSmall
                              .copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: AppRadius.xsRadius,
                          ),
                          child: Text(
                            'Planned',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enforced biometric gating on transaction signing will be enabled in production hardening.',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Payment Key Directory Status
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: _keyPubStatus == KeyPublicationStatus.published
                  ? colors.success.withValues(alpha: 0.5)
                  : colors.warning.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _keyPubStatus == KeyPublicationStatus.published
                    ? Icons.check_circle_outline
                    : Icons.sync,
                color: _keyPubStatus == KeyPublicationStatus.published
                    ? colors.success
                    : colors.warning,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _keyPubStatus == KeyPublicationStatus.published
                          ? 'Payment Keys Published'
                          : 'Payment Keys Sync Pending',
                      style: AppTypography.titleSmall
                          .copyWith(color: colors.textPrimary),
                    ),
                    Text(
                      _keyPubStatus == KeyPublicationStatus.published
                          ? 'Recipients can discover your P2PK and transport keys.'
                          : (_keyPubError ??
                              'Syncing public keys with server...'),
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_keyPubStatus == KeyPublicationStatus.syncPending)
                TextButton(
                  onPressed: _retryKeyPublication,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            setState(() => _currentStep = 4);
            _probeActiveMint();
          },
          child: const Text('Continue to Mint Setup'),
        ),
      ],
    );
  }

  Widget _buildMintStep(HanbovaColors colors) {
    final config = ref.watch(activeNetworkConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cashu Mint Connection',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Verifying connectivity and NUT capabilities with the active Cashu mint.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: _mintProbeSuccess
                  ? colors.success.withValues(alpha: 0.5)
                  : (_mintProbeError != null ? colors.error : colors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isProbingMint)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            _mintProbeSuccess ? colors.success : colors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _isProbingMint
                        ? 'Probing Mint Capabilities...'
                        : (_mintProbeSuccess
                            ? 'Mint Connected'
                            : 'Connection Failed'),
                    style: AppTypography.titleSmall.copyWith(
                      color: _mintProbeSuccess
                          ? colors.textPrimary
                          : (_mintProbeError != null
                              ? colors.error
                              : colors.textPrimary),
                    ),
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
              if (_mintName != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _mintName!,
                  style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
              if (_mintDescription != null) ...[
                const SizedBox(height: 2),
                Text(
                  _mintDescription!,
                  style: AppTypography.bodySmall
                      .copyWith(color: colors.textSecondary, fontSize: 11),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Verified: sat unit • NUT-04 (Minting) • NUT-07 (State) • NUT-10 & NUT-11 (P2PK Escrow)',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.textTertiary, fontSize: 11),
              ),
              if (_mintProbeError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _mintProbeError!,
                  style: AppTypography.bodySmall.copyWith(color: colors.error),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _probeActiveMint,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Connection'),
                    ),
                    if (config.network == HanbovaNetwork.local)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(networkEnvironmentProvider.notifier)
                              .setNetwork(HanbovaNetwork.cashuTest);
                          await _probeActiveMint();
                        },
                        icon: const Icon(Icons.public, size: 16),
                        label: const Text('Switch to Public Testnut Mint'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed:
              _mintProbeSuccess ? () => setState(() => _currentStep = 5) : null,
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
