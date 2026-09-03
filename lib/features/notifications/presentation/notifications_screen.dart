import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/security/privacy_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final demoState = ref.watch(demoModeProvider);
    final privacy = ref.watch(privacyProvider);

    final allNotifs = demoState.demoNotifications;
    final filtered = _selectedCategory == 'All'
        ? allNotifs
        : allNotifs
            .where((n) =>
                n.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Notifications Centre',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(demoModeProvider.notifier).markAllNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                'All',
                'Transaction',
                'Protected',
                'Bill',
                'eSIM',
                'Travel',
                'Security'
              ].map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.darkCardBackground,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = cat);
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
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: AppColors.darkTextSecondary
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You\'re all caught up on financial updates.',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return _buildNotificationCard(
                          notif, privacy.hideNotificationAmounts);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem notif, bool hideAmounts) {
    final (icon, color) = _getCategoryVisuals(notif.category);
    final timeStr = DateFormat('MMM d, h:mm a').format(notif.createdAt);

    return Dismissible(
      key: Key(notif.id),
      onDismissed: (_) {
        ref.read(demoModeProvider.notifier).markNotificationRead(notif.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.darkCardBackground
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.darkBorder
                : AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              notif.isRead ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  if (notif.amountFormatted != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      hideAmounts ? 'Amount: ••••••' : notif.amountFormatted!,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getCategoryVisuals(String category) {
    switch (category.toLowerCase()) {
      case 'transaction':
        return (Icons.currency_bitcoin, const Color(0xFF10B981));
      case 'protected':
        return (Icons.shield_outlined, const Color(0xFF38BDF8));
      case 'bill':
        return (Icons.flash_on_outlined, const Color(0xFFEAB308));
      case 'esim':
        return (Icons.sim_card_outlined, const Color(0xFF8B5CF6));
      case 'travel':
        return (Icons.flight_takeoff_outlined, const Color(0xFFEC4899));
      case 'security':
        return (Icons.lock_outline, const Color(0xFFEF4444));
      default:
        return (Icons.notifications_outlined, AppColors.primary);
    }
  }
}
