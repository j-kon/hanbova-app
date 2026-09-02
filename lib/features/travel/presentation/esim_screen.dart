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
    final market = ref.watch(marketProvider);
    final spendCountry = market.spendCountryInfo;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Travel Connectivity (eSIM)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkTextSecondary,
          tabs: const [
            Tab(text: 'Browse Plans'),
            Tab(text: 'My eSIMs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(spendCountry.name, spendCountry.flagEmoji),
                _buildMyEsimsTab(),
              ],
            ),
    );
  }

  Widget _buildBrowseTab(String countryName, String flagEmoji) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Simulation Environment Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SIMULATION ENVIRONMENT: Travel data plans and QR provisioning operate in safe pilot mode.',
                  style: TextStyle(
                    color: Colors.white70,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_packages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No eSIM plans available for this country currently.',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          )
        else
          ..._packages.map((p) => _buildPackageCard(p)),
      ],
    );
  }

  Widget _buildPackageCard(EsimPackage pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: const TextStyle(
                    color: Colors.white,
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pkg.priceSats} sats',
                  style: const TextStyle(
                    color: AppColors.primary,
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
              _buildMetaPill(Icons.data_usage, pkg.formattedData),
              const SizedBox(width: 8),
              _buildMetaPill(Icons.timer_outlined, '${pkg.validityDays} Days'),
              const SizedBox(width: 8),
              _buildMetaPill(Icons.speed, pkg.networkSpeed),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '≈ \$${pkg.priceFiat.toStringAsFixed(2)} ${pkg.currency}',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
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

  Widget _buildMetaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.darkTextSecondary, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEsimsTab() {
    if (_myProfiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sim_card_outlined,
                  size: 54, color: AppColors.darkTextSecondary),
              SizedBox(height: 16),
              Text(
                'No Active eSIMs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Browse available plans to activate high-speed travel roaming with Bitcoin.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
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
        return _buildProfileCard(prof);
      },
    );
  }

  Widget _buildProfileCard(EsimProfile prof) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prof.packageName,
                  style: const TextStyle(
                    color: Colors.white,
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
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Total: ${(prof.dataAllowanceMb / 1024).toStringAsFixed(0)} GB',
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: prof.dataRemainingFraction,
              backgroundColor: AppColors.darkSurface,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 16),

          // ICCID row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag,
                    color: AppColors.darkTextSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ICCID: ${prof.iccid}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: AppColors.primary, size: 16),
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
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.darkBorder),
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
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
    final market = ref.read(marketProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Confirm eSIM Purchase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan: ${pkg.name}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Data Allowance: ${pkg.formattedData}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Validity: ${pkg.validityDays} Days',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (Sats):',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${pkg.priceSats} sats',
                        style: const TextStyle(
                            color: AppColors.primary,
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
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
                  ref.read(transactionsProvider.notifier).recordEsimPurchase(
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
    final market = ref.read(marketProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Top Up eSIM Data',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile: ${prof.packageName}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('ICCID: ${prof.iccid}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                      fontSize: 12)),
              const SizedBox(height: 12),
              const Text('Add 3 GB High-Speed Roaming Data',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price:', style: TextStyle(color: Colors.white70)),
                    Text('15,000 sats',
                        style: TextStyle(
                            color: AppColors.primary,
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(transactionsProvider.notifier).recordEsimPurchase(
                      id: 'topup-${DateTime.now().millisecondsSinceEpoch}',
                      planName: '${prof.packageName} (+3 GB)',
                      amountSats: 15000,
                      fiatAmount: 9.00,
                      fiatCurrency: 'USD',
                      iccid: prof.iccid,
                      spendCountry: market.spendCountry,
                      isTopup: true,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
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
              const Text(
                'eSIM Installation Guide',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan the QR code or manually enter the activation code on your device.',
                style:
                    TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
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
                  color: AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SM-DP+ Address',
                        style: TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 11)),
                    Text(prof.smdpAddress,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    const Text('Activation Code (LPA String)',
                        style: TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 11)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            prof.qrCodeData,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: AppColors.primary, size: 18),
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
              const Text(
                'Instructions:\n• iOS: Settings → Cellular → Add eSIM → Use QR Code\n• Android: Settings → Network & internet → SIMs → Add eSIM',
                style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
