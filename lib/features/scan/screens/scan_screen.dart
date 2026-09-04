import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/network_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../send/domain/lightning_request_parser.dart';

/// Manual payment-request entry while camera scanning is unavailable.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _manualInputController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _manualInputController.dispose();
    super.dispose();
  }

  void _continueWithRequest() {
    final value = _manualInputController.text.trim();
    if (value.isEmpty) {
      setState(
          () => _validationMessage = 'Paste a payment request to continue.');
      return;
    }
    if (value.toLowerCase().startsWith('cashua') ||
        value.toLowerCase().startsWith('cashub')) {
      setState(
        () => _validationMessage = 'Cashu token import is not available yet.',
      );
      return;
    }
    if (value.startsWith('hnbv_claim_') || value.contains('/claim/')) {
      context.push('/claim?code=${Uri.encodeComponent(value)}');
      return;
    }

    try {
      final invoice = LightningRequestParser.parse(
        value,
        ref.read(networkEnvironmentProvider),
      );
      context.push('/send?invoice=${Uri.encodeComponent(invoice)}');
    } on InvalidLightningRequest catch (error) {
      setState(() => _validationMessage = error.message);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted || data?.text == null) return;
    setState(() {
      _manualInputController.text = data!.text!;
      _validationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: const Text('Enter payment request'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  border: Border.all(color: colors.border),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Camera scanning coming soon',
                            style: AppTypography.titleSmall.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'For now, paste a Lightning invoice or Hanbova claim code.',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Paste payment request',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _manualInputController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_validationMessage != null) {
                    setState(() => _validationMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Lightning invoice or Hanbova claim code',
                  errorText: _validationMessage,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste_outlined),
                label: const Text('Paste from clipboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _continueWithRequest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
