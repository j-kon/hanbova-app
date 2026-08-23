import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _manualInputController = TextEditingController();
  bool _showManualInput = false;

  @override
  void dispose() {
    _manualInputController.dispose();
    super.dispose();
  }

  void _processScannedCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    if (code.startsWith('hnbv_claim_') || code.contains('/claim/')) {
      // Hanbova Claim code
      context.push('/claim?code=$code');
    } else if (code.startsWith('lnbc') || code.startsWith('LNBC') || code.startsWith('lightning:')) {
      // Lightning invoice
      context.push('/send?invoice=$code');
    } else if (code.startsWith('@')) {
      // Hanbova handle
      context.push('/send?recipient=$code');
    } else {
      // Default to claim
      context.push('/claim?code=$code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showManualInput ? Icons.qr_code_scanner : Icons.keyboard, color: Colors.white),
            onPressed: () => setState(() => _showManualInput = !_showManualInput),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _showManualInput
                  ? Container(
                      color: colors.background,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter code or invoice',
                            style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _manualInputController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Paste Lightning invoice, Cashu token, or Hanbova claim code...',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () => _processScannedCode(_manualInputController.text),
                            child: const Text('Continue'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                _manualInputController.text = data!.text!;
                              }
                            },
                            icon: const Icon(Icons.paste, size: 18),
                            label: const Text('Paste from clipboard'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder Box
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.primary, width: 2),
                            borderRadius: AppRadius.lgRadius,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.primary, width: 4), left: BorderSide(color: colors.primary, width: 4)))),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.primary, width: 4), right: BorderSide(color: colors.primary, width: 4)))),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.primary, width: 4), left: BorderSide(color: colors.primary, width: 4)))),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.primary, width: 4), right: BorderSide(color: colors.primary, width: 4)))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: Colors.black,
              child: Text(
                'Align the QR code within the frame to scan automatically',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
