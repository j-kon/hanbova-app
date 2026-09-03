import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = navigationShell.currentIndex;

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
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.45)
                        : AppColors.charcoal.withValues(alpha: 0.08),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.graphite.withValues(alpha: 0.88)
                          : AppColors.warmWhite.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.8)
                            : AppColors.lightBorder.withValues(alpha: 0.9),
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

                        // 2. Pay (Everyday Pay Hub)
                        _IosNavItem(
                          icon: Icons.payments_outlined,
                          activeIcon: Icons.payments_rounded,
                          label: 'Pay',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onTap(context, 1),
                        ),

                        // 3. Activity
                        _IosNavItem(
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long_rounded,
                          label: 'Activity',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onTap(context, 2),
                        ),

                        // 4. Travel
                        _IosNavItem(
                          icon: Icons.flight_takeoff_outlined,
                          activeIcon: Icons.flight_takeoff_rounded,
                          label: 'Travel',
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.orangeLight,
                AppColors.bitcoinOrange,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.bitcoinOrange.withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.charcoal,
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
    final activeColor = AppColors.bitcoinOrange;
    final inactiveColor =
        isDark ? AppColors.darkTextTertiary : AppColors.softGray;

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
