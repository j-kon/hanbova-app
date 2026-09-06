import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:hanbova_app/features/send/presentation/send_screen.dart';
import 'package:intl/intl.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  ConsumerState<BeneficiariesScreen> createState() =>
      _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final demoState = ref.watch(demoModeProvider);
    final beneficiaries = demoState.demoBeneficiaries;

    final filtered = _selectedFilter == 'All'
        ? beneficiaries
        : beneficiaries.where((b) {
            if (_selectedFilter == 'Lightning' &&
                (b.type == 'lightning' || b.type == 'bitcoin')) {
              return true;
            }
            if (_selectedFilter == 'Mobile Money' && b.type == 'mobile_money') {
              return true;
            }
            if (_selectedFilter == 'Bank' && b.type == 'bank') {
              return true;
            }
            return false;
          }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'People & Beneficiaries',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBeneficiaryDialog(context),
        backgroundColor: colors.primary,
        foregroundColor: AppColors.charcoal,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Recipient',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['All', 'Lightning', 'Mobile Money', 'Bank'].map((cat) {
                final isSelected = cat == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.charcoal
                            : colors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceCard,
                    side: BorderSide(
                      color: isSelected ? colors.primary : colors.border,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedFilter = cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Beneficiaries Found',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save frequent recipients for instant one-tap transfers.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ben = filtered[index];
                      return _buildBeneficiaryCard(ben, colors);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard(BeneficiaryItem ben, HanbovaColors colors) {
    final (icon, color, typeLabel) = _getTypeVisuals(ben.type);
    final lastUsed = DateFormat('MMM d, yyyy').format(ben.lastUsedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ben.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  ben.handleOrAccount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primary.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ben.bankOrOperator != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${ben.bankOrOperator} • Last sent: $lastUsed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: Icon(Icons.send_rounded, color: colors.primary, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SendScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            icon: Icon(Icons.more_vert, color: colors.textSecondary, size: 18),
            color: colors.surfaceCard,
            onSelected: (val) {
              if (val == 'delete') {
                ref.read(demoModeProvider.notifier).removeBeneficiary(ben.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ben.name} removed from beneficiaries'),
                    backgroundColor: colors.primary,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
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
    );
  }

  (IconData, Color, String) _getTypeVisuals(String type) {
    switch (type.toLowerCase()) {
      case 'lightning':
        return (Icons.bolt, const Color(0xFFF59E0B), 'Lightning');
      case 'bitcoin':
        return (Icons.currency_bitcoin, const Color(0xFFF7931A), 'Bitcoin');
      case 'mobile_money':
        return (Icons.phone_android, const Color(0xFF10B981), 'Mobile Money');
      case 'bank':
        return (
          Icons.account_balance,
          const Color(0xFF38BDF8),
          'Bank Transfer'
        );
      default:
        return (Icons.person_outline, AppColors.primary, 'Contact');
    }
  }

  void _showAddBeneficiaryDialog(BuildContext context) {
    final colors = context.colors;
    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();
    String type = 'lightning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.surfaceCard,
          title: Text('Add Recipient',
              style: TextStyle(color: colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Recipient Name',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.border)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.primary)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: type,
                dropdownColor: colors.surfaceCard,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.border)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.primary)),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'lightning',
                      child: Text('Lightning Address',
                          style: TextStyle(color: colors.textPrimary))),
                  DropdownMenuItem(
                      value: 'mobile_money',
                      child: Text('Mobile Money Number',
                          style: TextStyle(color: colors.textPrimary))),
                  DropdownMenuItem(
                      value: 'bank',
                      child: Text('Bank Account',
                          style: TextStyle(color: colors.textPrimary))),
                  DropdownMenuItem(
                      value: 'bitcoin',
                      child: Text('Bitcoin Onchain Address',
                          style: TextStyle(color: colors.textPrimary))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: type == 'lightning'
                      ? 'e.g. user@getalby.com'
                      : type == 'mobile_money'
                          ? 'e.g. +254 712 345 678'
                          : type == 'bank'
                              ? 'Account Number & Bank'
                              : 'bc1q...',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.border)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.primary)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && handleCtrl.text.isNotEmpty) {
                  ref.read(demoModeProvider.notifier).addBeneficiary(
                        BeneficiaryItem(
                          id: 'ben-${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          handleOrAccount: handleCtrl.text.trim(),
                          type: type,
                          bankOrOperator: type == 'lightning'
                              ? 'Lightning Network'
                              : type == 'mobile_money'
                                  ? 'Mobile Provider'
                                  : 'Bank Account',
                          countryCode: 'NG',
                          lastUsedAt: DateTime.now(),
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${nameCtrl.text.trim()} added to beneficiaries!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
