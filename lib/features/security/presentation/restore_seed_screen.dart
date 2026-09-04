import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/crypto/mnemonic_service.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/wallet/wallet_context.dart';
import '../application/restore_wallet_controller.dart';

const restoredMessage =
    'Your signing keys and account identity have been restored. '
    'Ecash proofs stored locally on another device require local database transfer '
    'until server-assisted proof restoration (NUT-13) is supported.';
const syncPendingMessage =
    'Your wallet identity was restored, but payment-key sync is pending. '
    'Receiving protected payments may be unavailable until sync completes.';

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
    final isValid = await MnemonicService.validateMnemonic(phrase);
    if (!mounted) return;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid recovery phrase or checksum mismatch. Please check spelling.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace wallet identity?'),
        content: const Text(
          'This replaces the wallet identity for the signed-in account in this wallet environment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace Wallet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final result =
          await ref.read(restoreWalletControllerProvider).restore(phrase);
      if (!mounted) return;
      setState(() => _isRestoring = false);
      if (result.outcome == RestoreWalletOutcome.syncPending) {
        await _showSyncPendingDialog();
      } else {
        await _showRestoredDialog();
      }
    } on RestoreWalletFailure catch (failure) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFacingErrorMapper.from(
              AppFailure(message: 'Wallet restore failed', code: failure.code),
            ).message,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UserFacingErrorMapper.from(error).message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showRestoredDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wallet Restored'),
        content: const Text(restoredMessage),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/home');
            },
            child: const Text('Go to Wallet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSyncPendingDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wallet Restored — Sync Pending'),
        content: const Text(syncPendingMessage),
        actions: [
          TextButton(
            onPressed: () async {
              final synced = await ref
                  .read(restoreWalletControllerProvider)
                  .retryPublicKeySync();
              if (!dialogContext.mounted) return;
              if (synced) {
                Navigator.pop(dialogContext);
                if (mounted) await _showRestoredDialog();
                return;
              }
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Payment-key sync is still pending.'),
                ),
              );
            },
            child: const Text('Retry sync'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/home');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeContext = ref.watch(activeWalletContextKeyProvider);

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
        child: activeContext == null
            ? _buildAuthenticationRequired(colors)
            : Column(
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
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 4),
                                      child: Text(
                                        '${i + 1}.',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: colors.textTertiary),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _controllers[i],
                                        focusNode: _focusNodes[i],
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                                color: colors.textPrimary,
                                                fontSize: 13),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 8),
                                        ),
                                        onChanged: (val) =>
                                            _updateSuggestions(val),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                                color: colors.primary,
                                fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildAuthenticationRequired(HanbovaColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 42, color: colors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in to restore your wallet',
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.go('/login?next=%2Frestore-seed'),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
