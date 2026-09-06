import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'package:hanbova_app/features/travel/data/esim_service.dart';
import 'package:hanbova_app/features/travel/domain/esim_models.dart';

class EsimScreen extends ConsumerStatefulWidget {
  const EsimScreen({super.key});

  @override
  ConsumerState<EsimScreen> createState() => _EsimScreenState();
}

class _EsimScreenState extends ConsumerState<EsimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EsimPackage> _packages = [];
  List<EsimProfile> _myProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final market = ref.read(marketProvider);
    final service = ref.read(travelServiceProvider);

    final packages = await service.getEsimPackages(market.spendCountry);
    final profiles = await service.getMyProfiles();

    if (mounted) {
      setState(() {
        _packages = packages;
        _myProfiles = profiles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Travel Connectivity (eSIM)',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [
            Tab(text: 'Browse Plans'),
            Tab(text: 'My eSIMs'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(
                    spendCountry.name, spendCountry.flagEmoji, colors),
                _buildMyEsimsTab(colors),
              ],
            ),
    );
  }

  Widget _buildBrowseTab(
      String countryName, String flagEmoji, HanbovaColors colors) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Simulation Environment Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SIMULATION ENVIRONMENT: Travel data plans and QR provisioning operate in safe pilot mode.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Available Plans for $flagEmoji $countryName',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_packages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No eSIM plans available for this country currently.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          ..._packages.map((p) => _buildPackageCard(p, colors)),
      ],
    );
  }

  Widget _buildPackageCard(EsimPackage pkg, HanbovaColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pkg.priceSats} sats',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetaPill(Icons.data_usage, pkg.formattedData, colors),
              const SizedBox(width: 8),
              _buildMetaPill(
                  Icons.timer_outlined, '${pkg.validityDays} Days', colors),
              const SizedBox(width: 8),
              _buildMetaPill(Icons.speed, pkg.networkSpeed, colors),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '≈ \$${pkg.priceFiat.toStringAsFixed(2)} ${pkg.currency}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: AppColors.charcoal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => _showPurchaseDialog(pkg),
                child: const Text(
                  'Get Plan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text, HanbovaColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.textSecondary, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEsimsTab(HanbovaColors colors) {
    if (_myProfiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sim_card_outlined,
                  size: 54, color: colors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No Active eSIMs',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse available plans to activate high-speed travel roaming with Bitcoin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _myProfiles.length,
      itemBuilder: (context, index) {
        final prof = _myProfiles[index];
        return _buildProfileCard(prof, colors);
      },
    );
  }

  Widget _buildProfileCard(EsimProfile prof, HanbovaColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prof.packageName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prof.status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Data remaining progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data: ${prof.formattedRemaining} remaining',
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
              Text(
                'Total: ${(prof.dataAllowanceMb / 1024).toStringAsFixed(0)} GB',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: prof.dataRemainingFraction,
              backgroundColor: colors.surfaceElevated,
              color: colors.primary,
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 16),

          // ICCID row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.tag, color: colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ICCID: ${prof.iccid}',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: colors.primary, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prof.iccid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ICCID copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Actions: Installation Instructions & Top-Up
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showInstallationSheet(prof),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Setup QR / Code'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: AppColors.charcoal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showTopupDialog(prof),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Top Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(EsimPackage pkg) {
    final colors = context.colors;
    final market = ref.read(marketProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm eSIM Purchase',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan: ${pkg.name}',
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 6),
              Text('Data Allowance: ${pkg.formattedData}',
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 6),
              Text('Validity: ${pkg.validityDays} Days',
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total (Sats):',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold)),
                    Text('${pkg.priceSats} sats',
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final service = ref.read(travelServiceProvider);
                  final profile = await service.purchaseEsim(pkg.id);
                  setState(() {
                    _myProfiles.insert(0, profile);
                  });

                  // Log to activity
                  await ref
                      .read(transactionsProvider.notifier)
                      .recordEsimPurchase(
                        id: profile.iccid,
                        planName: pkg.name,
                        amountSats: pkg.priceSats,
                        fiatAmount: pkg.priceFiat,
                        fiatCurrency: pkg.currency,
                        iccid: profile.iccid,
                        qrCode: profile.qrCodeData,
                        spendCountry: market.spendCountry,
                      );

                  _tabController.animateTo(1);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('eSIM Profile allocated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirm & Pay',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showTopupDialog(EsimProfile prof) {
    final colors = context.colors;
    final market = ref.read(marketProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Top Up eSIM Data',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile: ${prof.packageName}',
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 6),
              Text('ICCID: ${prof.iccid}',
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 12)),
              const SizedBox(height: 12),
              Text('Add 3 GB High-Speed Roaming Data',
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price:',
                        style: TextStyle(color: colors.textSecondary)),
                    Text('15,000 sats',
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                await ref
                    .read(transactionsProvider.notifier)
                    .recordEsimPurchase(
                      id: 'topup-${DateTime.now().millisecondsSinceEpoch}',
                      planName: '${prof.packageName} (+3 GB)',
                      amountSats: 15000,
                      fiatAmount: 9.00,
                      fiatCurrency: 'USD',
                      iccid: prof.iccid,
                      spendCountry: market.spendCountry,
                      isTopup: true,
                    );
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('eSIM Top-up confirmed and active!')),
                );
              },
              child: const Text('Confirm Top-Up',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showInstallationSheet(EsimProfile prof) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'eSIM Installation Guide',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan the QR code or manually enter the activation code on your device.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Mock QR Display container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2,
                          size: 140, color: Colors.black),
                      const SizedBox(height: 4),
                      Text(
                        prof.matchingId,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Activation Code Copy Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SM-DP+ Address',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 11)),
                    Text(prof.smdpAddress,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    Text('Activation Code (LPA String)',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 11)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            prof.qrCodeData,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 12,
                                fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.copy, color: colors.primary, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: prof.qrCodeData));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Activation code copied')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Instructions:\n• iOS: Settings → Cellular → Add eSIM → Use QR Code\n• Android: Settings → Network & internet → SIMs → Add eSIM',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
