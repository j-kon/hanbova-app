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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Saved Billers & Payments',
          style: TextStyle(
            color: colors.textPrimary,
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
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Saved Billers',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your meters, phone numbers, and utility accounts for quick recurring payments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
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
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flash_on_outlined,
                    color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.billerName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account / Ref: ${item.accountReference}',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: colors.textSecondary, size: 18),
                color: colors.surfaceCard,
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
                        backgroundColor: colors.primary,
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) {
                  final popupColors = ctx.colors;
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: popupColors.textPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text('Edit Reference',
                              style: TextStyle(color: popupColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
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
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
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
      builder: (ctx) {
        final dialogColors = ctx.colors;
        return AlertDialog(
          backgroundColor: dialogColors.surfaceCard,
          title: Text('Edit Saved Biller',
              style: TextStyle(color: dialogColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: dialogColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Label / Name',
                  labelStyle: TextStyle(color: dialogColors.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: refCtrl,
                style: TextStyle(color: dialogColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Account / Meter Number',
                  labelStyle: TextStyle(color: dialogColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: dialogColors.textSecondary)),
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
                backgroundColor: dialogColors.primary,
                foregroundColor: AppColors.charcoal,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}
