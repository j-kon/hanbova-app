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
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                key: const Key('main-navigation'),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                ),
                child: Row(children: [
                  Expanded(
                      child: _IosNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onTap(context, 0))),
                  Expanded(
                      child: _IosNavItem(
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long_rounded,
                          label: 'Activity',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onTap(context, 2))),
                  Expanded(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _CenterActionButton(
                        key: const Key('navbar_center_action_button'),
                        onTap: () => PayActionSheet.show(context)),
                    const SizedBox(height: 2),
                    ExcludeSemantics(
                        child: Text('Pay',
                            style: AppTypography.labelSmall
                                .copyWith(color: colors.textPrimary))),
                  ])),
                  Expanded(
                      child: _IosNavItem(
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet_rounded,
                          label: 'Money',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onTap(context, 3))),
                  Expanded(
                      child: _IosNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profile',
                          isSelected: selectedIndex == 4,
                          onTap: () => _onTap(context, 4))),
                ]),
              ),
            ),
    );
  }
}

class _CenterActionButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterActionButton({super.key, required this.onTap});

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      key: const Key('center-pay-button'),
      button: true,
      label: 'Pay',
      child: SizedBox(
        width: 56,
        height: 56,
        child: InkResponse(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
          radius: 28,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: Container(
              margin: const EdgeInsets.all(3),
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
                    color: AppColors.bitcoinOrange
                        .withValues(alpha: isDark ? 0.45 : 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.charcoal,
                  size: 26,
                ),
              ),
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
    final colors = context.colors;
    final isDark = context.isDark;
    final activeColor = colors.primary;
    final inactiveColor = colors.textSecondary;

    return Semantics(
      button: true,
      excludeSemantics: true,
      selected: isSelected,
      label: label,
      child: SizedBox(
        width: 52,
        height: 52,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.16 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
