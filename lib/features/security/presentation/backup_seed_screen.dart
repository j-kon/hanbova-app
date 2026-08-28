import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/crypto/mnemonic_service.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';

final walletBackupStatusProvider = StateProvider<bool>((ref) => false);

class BackupSeedScreen extends ConsumerStatefulWidget {
  const BackupSeedScreen({super.key});

  @override
  ConsumerState<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends ConsumerState<BackupSeedScreen> {
  List<String> _words = [];
  bool _isLoading = true;
  bool _isRevealed = false;
  int _currentStep = 0; // 0: View words, 1: Quiz, 2: Success

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalletMnemonic());
  }

  Future<void> _loadWalletMnemonic() async {
    final authState = ref.read(authProvider);
    String phrase;

    if (authState.user != null) {
      final identity =
          await ref.read(cryptoIdentityProvider.notifier).getOrCreateIdentity();
      phrase = identity.mnemonic;
    } else {
      phrase = await MnemonicService.generateMnemonic();
    }

    if (!mounted) return;

    final words = phrase.split(' ');
    setState(() {
      _words = words;
      _isLoading = false;
      _prepareQuiz(words);
    });
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

  Future<void> _revealWords() async {
    final bio = ref.read(biometricServiceProvider);
    final authorized =
        await bio.authenticate(reason: 'Authenticate to view recovery phrase');
    if (authorized && mounted) {
      setState(() => _isRevealed = true);
    }
  }

  void _verifyQuiz() {
    final correct1 = _selectedWord1 == _words[_quizWordIndex1];
    final correct2 = _selectedWord2 == _words[_quizWordIndex2];
    final correct3 = _selectedWord3 == _words[_quizWordIndex3];

    if (correct1 && correct2 && correct3) {
      ref.read(walletBackupStatusProvider.notifier).state = true;
      setState(() => _currentStep = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Incorrect words selected. Please double-check your recovery phrase.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Recovery Phrase Backup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _currentStep == 0
                    ? _buildViewWordsStep(colors)
                    : _currentStep == 1
                        ? _buildQuizStep(colors)
                        : _buildSuccessStep(colors),
              ),
      ),
    );
  }

  Widget _buildViewWordsStep(HanbovaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.redAccent, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secret Recovery Phrase',
                      style: AppTypography.titleSmall
                          .copyWith(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Write these 12 words down in order on paper. Never share them or take a digital screenshot.',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 12 Words Grid
        Stack(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: _words.length,
              itemBuilder: (context, i) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style: AppTypography.bodySmall.copyWith(
                            color: colors.textTertiary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isRevealed ? _words[i] : '••••••••',
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontFamily: _isRevealed ? null : 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (!_isRevealed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.background.withValues(alpha: 0.85),
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _revealWords,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Tap to Reveal 12 Words'),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        ElevatedButton(
          onPressed:
              _isRevealed ? () => setState(() => _currentStep = 1) : null,
          child: const Text('I Have Written It Down -> Continue'),
        ),
      ],
    );
  }

  Widget _buildQuizStep(HanbovaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify Recovery Phrase',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the correct words corresponding to their positions to confirm your backup.',
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildQuizQuestion(
            'Word #${_quizWordIndex1 + 1}', _options1, _selectedWord1, (w) {
          setState(() => _selectedWord1 = w);
        }, colors),
        const SizedBox(height: AppSpacing.md),
        _buildQuizQuestion(
            'Word #${_quizWordIndex2 + 1}', _options2, _selectedWord2, (w) {
          setState(() => _selectedWord2 = w);
        }, colors),
        const SizedBox(height: AppSpacing.md),
        _buildQuizQuestion(
            'Word #${_quizWordIndex3 + 1}', _options3, _selectedWord3, (w) {
          setState(() => _selectedWord3 = w);
        }, colors),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: (_selectedWord1 != null &&
                  _selectedWord2 != null &&
                  _selectedWord3 != null)
              ? _verifyQuiz
              : null,
          child: const Text('Verify & Complete Backup'),
        ),
      ],
    );
  }

  Widget _buildQuizQuestion(
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
          const SizedBox(height: AppSpacing.sm),
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

  Widget _buildSuccessStep(HanbovaColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_rounded,
                color: colors.success, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Wallet Successfully Backed Up!',
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your 12-word recovery phrase has been verified for this test environment. In this beta build, your cryptographic keys remain securely stored on this device.',
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/me'),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
