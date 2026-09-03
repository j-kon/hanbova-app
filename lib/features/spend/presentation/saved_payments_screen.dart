import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/spend/domain/bill_models.dart';
import 'package:hanbova_app/features/spend/presentation/spend_screen.dart';

class SavedPaymentsScreen extends ConsumerStatefulWidget {
  const SavedPaymentsScreen({super.key});

  @override
  ConsumerState<SavedPaymentsScreen> createState() =>
      _SavedPaymentsScreenState();
}

class _SavedPaymentsScreenState extends ConsumerState<SavedPaymentsScreen> {
  final List<SavedBillerItem> _savedBillers = [
    const SavedBillerItem(
      id: 'sb-1',
      billerId: 'ke_kplc_prepaid',
      billerName: 'Kenya Power (KPLC Prepaid)',
      accountReference: '14123456789',
      serviceType: BillServiceType.electricity,
      countryCode: 'KE',
    ),
    const SavedBillerItem(
      id: 'sb-2',
      billerId: 'ke_safaricom_airtime',
      billerName: 'Safaricom Airtime',
      accountReference: '0712345678',
      serviceType: BillServiceType.airtime,
      countryCode: 'KE',
    ),
    const SavedBillerItem(
      id: 'sb-3',
      billerId: 'ng_mtn_data',
      billerName: 'MTN Data Bundles',
      accountReference: '08031234567',
      serviceType: BillServiceType.data,
      countryCode: 'NG',
    ),
    const SavedBillerItem(
      id: 'sb-4',
      billerId: 'gh_ecg',
      billerName: 'Electricity Company of Ghana',
      accountReference: 'P12345678',
      serviceType: BillServiceType.electricity,
      countryCode: 'GH',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Saved Billers & Payments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _savedBillers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Billers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save your meters, phone numbers, and utility accounts for quick recurring payments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _savedBillers.length,
              itemBuilder: (context, index) {
                final item = _savedBillers[index];
                return _buildSavedBillerCard(item);
              },
            ),
    );
  }

  Widget _buildSavedBillerCard(SavedBillerItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.billerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account / Ref: ${item.accountReference}',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.darkTextSecondary, size: 18),
                color: AppColors.darkCardBackground,
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditDialog(item);
                  } else if (val == 'delete') {
                    setState(() {
                      _savedBillers.removeWhere((b) => b.id == item.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${item.billerName} removed from saved billers'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Reference',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpendScreen()),
                );
              },
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: const Text('Pay Again', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(SavedBillerItem item) {
    final nameCtrl = TextEditingController(text: item.billerName);
    final refCtrl = TextEditingController(text: item.accountReference);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBackground,
        title: const Text('Edit Saved Biller',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Label / Name',
                labelStyle: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: refCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Account / Meter Number',
                labelStyle: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved biller updated!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
