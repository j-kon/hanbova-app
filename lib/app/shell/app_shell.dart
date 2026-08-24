import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'pay_action_sheet.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      // Central Pay button opens modal action sheet
      PayActionSheet.show(context);
      return;
    }

    // Map tab index to branch index (0 -> 0, 1 -> 1, 3 -> 2, 4 -> 3)
    final branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _calculateSelectedIndex() {
    final branchIndex = navigationShell.currentIndex;
    return branchIndex >= 2 ? branchIndex + 1 : branchIndex;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. Full-screen scrolling screen content
          Positioned.fill(
            child: navigationShell,
          ),

          // 2. Floating iOS Frosted Glass Navbar (Truly transparent surroundings)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding > 0 ? bottomPadding + 6 : 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.45)
                        : const Color(0xFF012D1B).withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.forestGreen.withValues(alpha: 0.82)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? AppColors.ribbonGreen.withValues(alpha: 0.8)
                            : const Color(0xFFE8E3D8).withValues(alpha: 0.9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 1. Home
                        _IosNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onTap(context, 0),
                        ),

                        // 2. Activity
                        _IosNavItem(
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long_rounded,
                          label: 'Activity',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onTap(context, 1),
                        ),

                        // 3. Center Pay Floating Action Button
                        _CenterPayButton(
                          onTap: () => _onTap(context, 2),
                        ),

                        // 4. Protected
                        _IosNavItem(
                          icon: Icons.shield_outlined,
                          activeIcon: Icons.shield_rounded,
                          label: 'Protected',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onTap(context, 3),
                        ),

                        // 5. Me / Profile
                        _IosNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Me',
                          isSelected: selectedIndex == 4,
                          onTap: () => _onTap(context, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterPayButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterPayButton({required this.onTap});

  @override
  State<_CenterPayButton> createState() => _CenterPayButtonState();
}

class _CenterPayButtonState extends State<_CenterPayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.lightLeaf,
                      AppColors.leafGreen,
                    ]
                  : [
                      AppColors.ribbonGreen,
                      AppColors.forestGreen,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.leafGreen : AppColors.forestGreen)
                    .withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.swap_horiz_rounded,
              color: isDark ? AppColors.deepForest : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _IosNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IosNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.leafGreen : AppColors.forestGreen;
    final inactiveColor =
        isDark ? const Color(0xFF7D8F87) : AppColors.softCharcoal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.16 : 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
