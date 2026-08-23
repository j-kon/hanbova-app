import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/mint_validator.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class CustomMintEntry {
  final String url;
  final String name;
  final bool isNut11Supported;
  final bool isDefault;

  const CustomMintEntry({
    required this.url,
    required this.name,
    required this.isNut11Supported,
    this.isDefault = false,
  });
}

final configuredMintsProvider = StateProvider<List<CustomMintEntry>>((ref) {
  final currentNet = ref.watch(networkEnvironmentProvider);
  final netCfg = NetworkConfig.fromNetwork(currentNet);

  return [
    CustomMintEntry(
      url: netCfg.defaultMintUrl,
      name: netCfg.displayName,
      isNut11Supported: true,
      isDefault: true,
    ),
    const CustomMintEntry(
      url: 'https://testnut.cashu.space',
      name: 'Cashu Space Testnut (NUT-11 enabled)',
      isNut11Supported: true,
      isDefault: false,
    ),
  ];
});

class MintsScreen extends ConsumerStatefulWidget {
  const MintsScreen({super.key});

  @override
  ConsumerState<MintsScreen> createState() => _MintsScreenState();
}

class _MintsScreenState extends ConsumerState<MintsScreen> {
  final _mintUrlController = TextEditingController();
  bool _isProbing = false;
  String? _probeError;

  @override
  void dispose() {
    _mintUrlController.dispose();
    super.dispose();
  }

  void _showAddMintSheet() {
    _mintUrlController.clear();
    _probeError = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final colors = context.colors;

          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Add Custom Cashu Mint', style: AppTypography.titleMedium.copyWith(color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hanbova will probe the mint endpoint to verify NUT-06 info and NUT-11 Protected Payment support.',
                  style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _mintUrlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Mint URL',
                    hintText: 'https://mint.example.com',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                ),
                if (_probeError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_probeError!, style: AppTypography.bodySmall.copyWith(color: Colors.redAccent)),
                ],
                const SizedBox(height: AppSpacing.lg),

                ElevatedButton.icon(
                  onPressed: _isProbing
                      ? null
                      : () async {
                          final url = _mintUrlController.text.trim();
                          if (url.isEmpty || !url.startsWith('http')) {
                            setModalState(() => _probeError = 'Please enter a valid HTTP/HTTPS mint URL');
                            return;
                          }

                          setModalState(() {
                            _isProbing = true;
                            _probeError = null;
                          });

                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          final validator = MintValidator();
                          final result = await validator.validateMint(url);

                          if (!mounted) return;
                          setModalState(() => _isProbing = false);

                          if (result.isValid && result.nut11Supported) {
                            final name = result.mintName ?? 'Custom Mint';
                            ref.read(configuredMintsProvider.notifier).update((list) => [
                                  ...list,
                                  CustomMintEntry(
                                    url: url,
                                    name: name,
                                    isNut11Supported: true,
                                  ),
                                ]);
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Added $name successfully!')),
                            );
                          } else if (result.isValid && !result.nut11Supported) {
                            setModalState(() => _probeError = 'Mint is online, but NUT-11 (P2PK) is not enabled.');
                          } else {
                            setModalState(() => _probeError = 'Failed to connect to mint: ${result.errorMessage}');
                          }
                        },
                  icon: _isProbing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Probe & Add Mint'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mints = ref.watch(configuredMintsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Connected Mints'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Mint',
            onPressed: _showAddMintSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Hanbova supports multi-mint routing. Never combine proofs across different mints.',
                      style: AppTypography.bodySmall.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...mints.map((mint) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: mint.isDefault ? colors.primary : colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_rounded, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(mint.name, style: AppTypography.titleSmall.copyWith(color: colors.textPrimary)),
                              if (mint.isDefault) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Active', style: AppTypography.labelSmall.copyWith(color: colors.primary, fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(mint.url, style: AppTypography.bodySmall.copyWith(color: colors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: colors.success, size: 18),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            OutlinedButton.icon(
              onPressed: _showAddMintSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Mint'),
            ),
          ],
        ),
      ),
    );
  }
}
