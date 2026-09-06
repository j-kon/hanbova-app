import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/crypto/bip39_words.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/sensitive_screen_protection.dart';
import '../../../core/security/wallet_backup_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/wallet/wallet_context.dart';
import '../../../l10n/app_localizations.dart';

class BackupSeedScreen extends ConsumerStatefulWidget {
  const BackupSeedScreen({super.key});

  @override
  ConsumerState<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends ConsumerState<BackupSeedScreen> {
  List<String> _words = [];
  bool _isLoading = true;
  bool _isConfirming = false;
  bool _isRevealed = false;
  WalletContextKey? _loadedContext;
  String? _loadError;
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
    try {
      await ref.read(cryptoIdentityProvider.future);
      final identity =
          await ref.read(cryptoIdentityProvider.notifier).requireIdentity();
      if (!mounted) return;

      final words = identity.mnemonic.split(' ');
      setState(() {
        _words = words;
        _loadedContext = identity.context;
        _loadError = null;
        _isLoading = false;
        _prepareQuiz(words);
      });
    } on WalletContextUnavailableException {
      _showUnavailable();
    } on WalletIdentityUnavailableException {
      _showUnavailable();
    } on StaleWalletContextException {
      _showUnavailable();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _words = [];
        _loadedContext = null;
        _loadError = 'Could not load the recovery phrase.';
        _isLoading = false;
      });
    }
  }

  void _showUnavailable() {
    if (!mounted) return;
    setState(() {
      _words = [];
      _loadedContext = null;
      _loadError = 'Wallet unavailable';
      _isLoading = false;
    });
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

  Future<void> _revealWords() async {
    final bio = ref.read(biometricServiceProvider);
    final authorized =
        await bio.authenticate(reason: 'Authenticate to view recovery phrase');
    if (!mounted) return;
    if (authorized) {
      setState(() => _isRevealed = true);
      return;
    }
    setState(() => _isRevealed = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authentication was not completed.')),
    );
  }

  Future<void> _verifyQuiz() async {
    final correct1 = _selectedWord1 == _words[_quizWordIndex1];
    final correct2 = _selectedWord2 == _words[_quizWordIndex2];
    final correct3 = _selectedWord3 == _words[_quizWordIndex3];

    if (correct1 && correct2 && correct3) {
      setState(() => _isConfirming = true);
      try {
        await ref.read(walletBackupStatusProvider.notifier).confirm();
        if (!mounted) return;
        setState(() {
          _isConfirming = false;
          _currentStep = 2;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup confirmation could not be saved.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
    final l10n = AppLocalizations.of(context)!;
    final activeContext = ref.watch(activeWalletContextKeyProvider);
    final contextMatches =
        _loadedContext != null && _loadedContext == activeContext;

    return SensitiveScreenProtection(
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(l10n.recoveryPhraseBackup),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null || !contextMatches
                  ? _buildUnavailableState(colors)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _currentStep == 0
                          ? _buildViewWordsStep(colors)
                          : _currentStep == 1
                              ? _buildQuizStep(colors)
                              : _buildSuccessStep(colors),
                    ),
        ),
      ),
    );
  }

  Widget _buildUnavailableState(HanbovaColors colors) {
    final l10n = AppLocalizations.of(context)!;
    final message = _loadError ?? l10n.walletUnavailable;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: colors.textSecondary, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_loadError != 'Wallet unavailable') ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });
                  _loadWalletMnemonic();
                },
                child: Text(l10n.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewWordsStep(HanbovaColors colors) {
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.secretRecoveryPhrase,
                      style: AppTypography.titleSmall
                          .copyWith(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recoveryPhraseSafetyNotice,
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
                      label: Text(l10n.revealTwelveWords),
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
          child: Text(l10n.continueAfterBackup),
        ),
      ],
    );
  }

  Widget _buildQuizStep(HanbovaColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifyRecoveryPhrase,
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.verifyRecoveryPhraseDescription,
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildQuizQuestion(
            l10n.wordPosition(_quizWordIndex1 + 1), _options1, _selectedWord1,
            (w) {
          setState(() => _selectedWord1 = w);
        }, colors),
        const SizedBox(height: AppSpacing.md),
        _buildQuizQuestion(
            l10n.wordPosition(_quizWordIndex2 + 1), _options2, _selectedWord2,
            (w) {
          setState(() => _selectedWord2 = w);
        }, colors),
        const SizedBox(height: AppSpacing.md),
        _buildQuizQuestion(
            l10n.wordPosition(_quizWordIndex3 + 1), _options3, _selectedWord3,
            (w) {
          setState(() => _selectedWord3 = w);
        }, colors),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: (_selectedWord1 != null &&
                  _selectedWord2 != null &&
                  _selectedWord3 != null)
              ? (_isConfirming ? null : _verifyQuiz)
              : null,
          child: Text(
            _isConfirming ? l10n.saving : l10n.verifyAndCompleteBackup,
          ),
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
    final l10n = AppLocalizations.of(context)!;
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
          l10n.walletSuccessfullyBackedUp,
          style: AppTypography.headline.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.backupSuccessDescription,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/me'),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}
