import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/crypto/mnemonic_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'backup_seed_screen.dart';

class RestoreSeedScreen extends ConsumerStatefulWidget {
  const RestoreSeedScreen({super.key});

  @override
  ConsumerState<RestoreSeedScreen> createState() => _RestoreSeedScreenState();
}

class _RestoreSeedScreenState extends ConsumerState<RestoreSeedScreen> {
  final List<TextEditingController> _controllers =
      List.generate(12, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());
  int _activeField = 0;
  List<String> _suggestions = [];
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 12; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _activeField = i;
            _updateSuggestions(_controllers[i].text);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateSuggestions(String text) {
    if (text.isEmpty) {
      setState(() => _suggestions = []);
    } else {
      setState(() {
        _suggestions = MnemonicService.getWordSuggestions(text);
      });
    }
  }

  void _selectSuggestion(String word) {
    _controllers[_activeField].text = word;
    _updateSuggestions('');

    if (_activeField < 11) {
      _focusNodes[_activeField + 1].requestFocus();
    } else {
      _focusNodes[_activeField].unfocus();
    }
  }

  Future<void> _restoreWallet() async {
    final words = _controllers.map((c) => c.text.trim().toLowerCase()).toList();
    if (words.any((w) => w.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill in all 12 words of your recovery phrase')),
      );
      return;
    }

    final phrase = words.join(' ');
    setState(() => _isRestoring = true);

    try {
      final isValid = await MnemonicService.validateMnemonic(phrase);
      if (!isValid) {
        if (!mounted) return;
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Invalid recovery phrase or checksum mismatch. Please check spelling.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await ref.read(cryptoIdentityProvider.notifier).restoreFromMnemonic(
            mnemonic: phrase,
          );

      ref.read(walletBackupStatusProvider.notifier).state = true;
      ref.invalidate(cashuBalanceProvider);

      if (!mounted) return;
      setState(() => _isRestoring = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Wallet Restored!'),
          content: const Text(
            'Your wallet identity has been restored. Ecash balance recovery after complete device loss is still experimental in this test build.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: const Text('Go to Wallet'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore wallet: $e'),
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
        title: const Text('Restore from Phrase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Your 12-Word Phrase',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Type in your recovery words in the exact sequence they were generated.',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 12 Words Input Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceCard,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: _activeField == i
                                  ? colors.primary
                                  : colors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 4),
                                child: Text(
                                  '${i + 1}.',
                                  style: AppTypography.labelSmall
                                      .copyWith(color: colors.textTertiary),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: AppTypography.titleSmall.copyWith(
                                      color: colors.textPrimary, fontSize: 13),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                  ),
                                  onChanged: (val) => _updateSuggestions(val),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    ElevatedButton.icon(
                      onPressed: _isRestoring ? null : _restoreWallet,
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Restore Wallet'),
                    ),
                  ],
                ),
              ),
            ),

            // Word Autocomplete Strip
            if (_suggestions.isNotEmpty)
              Container(
                height: 52,
                color: colors.surfaceElevated,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, idx) {
                    final sug = _suggestions[idx];
                    return ActionChip(
                      label: Text(sug),
                      onPressed: () => _selectSuggestion(sug),
                      backgroundColor: colors.surfaceCard,
                      labelStyle: AppTypography.bodySmall.copyWith(
                          color: colors.primary, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
