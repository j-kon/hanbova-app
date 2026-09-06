import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = context.isDark;
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    key: const Key('main-navigation'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: colors.border
                            .withValues(alpha: isDark ? 0.35 : 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LiquidNavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Home',
                            isSelected: selectedIndex == 0,
                            onTap: () => _onTap(context, 0),
                          ),
                        ),
                        Expanded(
                          child: _LiquidNavItem(
                            icon: Icons.receipt_long_outlined,
                            activeIcon: Icons.receipt_long_rounded,
                            label: 'Activity',
                            isSelected: selectedIndex == 2,
                            onTap: () => _onTap(context, 2),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CenterActionButton(
                                key: const Key('navbar_center_action_button'),
                                onTap: () => PayActionSheet.show(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _LiquidNavItem(
                            icon: Icons.account_balance_wallet_outlined,
                            activeIcon: Icons.account_balance_wallet_rounded,
                            label: 'Money',
                            isSelected: selectedIndex == 3,
                            onTap: () => _onTap(context, 3),
                          ),
                        ),
                        Expanded(
                          child: _LiquidNavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                            isSelected: selectedIndex == 4,
                            onTap: () => _onTap(context, 4),
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

class _CenterActionButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterActionButton({super.key, required this.onTap});

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _squishController;

  @override
  void initState() {
    super.initState();
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _squishController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _squishController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails _) {
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
    );
  }

  void _handleTapCancel() {
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
    );
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
    );
    widget.onTap();
  }

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
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          radius: 28,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          splashColor: AppColors.bitcoinOrange.withValues(alpha: 0.22),
          highlightColor: Colors.transparent,
          child: AnimatedBuilder(
            animation: _squishController,
            builder: (context, child) {
              final squish = _squishController.value;
              final scaleX = 1.0 + (0.08 * squish);
              final scaleY = 1.0 - (0.12 * squish);
              final translateY = 1.8 * squish;

              return Transform.translate(
                offset: Offset(0.0, translateY),
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
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

class _LiquidNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LiquidNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LiquidNavItem> createState() => _LiquidNavItemState();
}

class _LiquidNavItemState extends State<_LiquidNavItem>
    with TickerProviderStateMixin {
  late final AnimationController _squishController;
  late final AnimationController _rippleController;
  Offset _touchPosition = const Offset(26, 26);

  @override
  void initState() {
    super.initState();
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _squishController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
    });
    _squishController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails _) {
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
    );
  }

  void _handleTapCancel() {
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _rippleController.forward(from: 0.0);
    _squishController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
    );
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final activeColor = colors.primary;
    final inactiveColor = colors.textSecondary;

    return Semantics(
      button: true,
      excludeSemantics: true,
      selected: widget.isSelected,
      label: widget.label,
      child: SizedBox(
        width: 52,
        height: 52,
        child: InkWell(
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(26),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedBuilder(
            animation: Listenable.merge([_squishController, _rippleController]),
            builder: (context, child) {
              final squish = _squishController.value;
              // Fluid deformation: compresses vertically, bulges horizontally, and dips down
              final scaleX = 1.0 + (0.10 * squish);
              final scaleY = 1.0 - (0.12 * squish);
              final translateY = 1.6 * squish;

              return Transform.translate(
                offset: Offset(0.0, translateY),
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: _LiquidRipplePainter(
                      progress: _rippleController.value,
                      origin: _touchPosition,
                      color: activeColor,
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                          activeColor.withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
                border: widget.isSelected
                    ? Border.all(
                        color:
                            activeColor.withValues(alpha: isDark ? 0.32 : 0.20),
                        width: 1,
                      )
                    : Border.all(color: Colors.transparent, width: 1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: widget.isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        widget.isSelected ? widget.activeIcon : widget.icon,
                        color: widget.isSelected ? activeColor : inactiveColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.isSelected ? activeColor : inactiveColor,
                        fontSize: 10.5,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedScale(
                      scale: widget.isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidRipplePainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color color;

  _LiquidRipplePainter({
    required this.progress,
    required this.origin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final curved = Curves.easeOutCubic.transform(progress);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) * 0.7;
    final currentRadius = maxRadius * curved;
    final alpha = (1.0 - Curves.easeInCubic.transform(progress)) * 0.35;

    final dropletPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * 0.8),
          color.withValues(alpha: alpha * 0.4),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: currentRadius));

    canvas.drawCircle(origin, currentRadius, dropletPaint);

    if (curved > 0.15) {
      final ringProgress = (curved - 0.15) / 0.85;
      final ringAlpha = (1.0 - ringProgress) * 0.25;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - ringProgress * 0.5)
        ..color = color.withValues(alpha: ringAlpha);
      canvas.drawCircle(origin, currentRadius * 0.9, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_LiquidRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.color != color;
  }
}
