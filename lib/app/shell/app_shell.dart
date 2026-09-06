import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'pay_action_sheet.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liquidTransferController;
  late double _fromSlot;
  late double _toSlot;

  @override
  void initState() {
    super.initState();
    final initialSlot =
        _slotForIndex(widget.navigationShell.currentIndex).toDouble();
    _fromSlot = initialSlot;
    _toSlot = initialSlot;
    _liquidTransferController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _liquidTransferController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIndex = oldWidget.navigationShell.currentIndex;
    final newIndex = widget.navigationShell.currentIndex;
    if (oldIndex != newIndex) {
      final targetSlot = _slotForIndex(newIndex).toDouble();
      if (targetSlot != _toSlot) {
        _startLiquidTransfer(_toSlot, targetSlot);
      }
    }
  }

  double _slotForIndex(int index) {
    switch (index) {
      case 0:
        return 0.0; // Home
      case 2:
        return 1.0; // Activity
      case 1:
        return 2.0; // Pay
      case 3:
        return 3.0; // Money
      case 4:
        return 4.0; // Profile
      default:
        return 0.0;
    }
  }

  void _startLiquidTransfer(double from, double to) {
    if (from == to && _liquidTransferController.isCompleted) return;
    setState(() {
      _fromSlot = from;
      _toSlot = to;
    });
    _liquidTransferController.forward(from: 0.0);
  }

  void _onTap(BuildContext context, int index) {
    final targetSlot = _slotForIndex(index);
    final currentSlot = _fromSlot +
        (_toSlot - _fromSlot) *
            Curves.easeInOutCubic.transform(_liquidTransferController.value);
    _startLiquidTransfer(currentSlot, targetSlot);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Widget _buildLiquidTransferPill({
    required double totalWidth,
    required double totalHeight,
    required Color activeColor,
    required bool isDark,
  }) {
    final slotWidth = totalWidth / 5.0;
    final basePillWidth = math.min(slotWidth - 8.0, 56.0);
    const basePillHeight = 46.0;
    final centerY = totalHeight / 2.0;

    final t = _liquidTransferController.value;

    double left;
    double right;

    if (_fromSlot == _toSlot) {
      final center = (_toSlot + 0.5) * slotWidth;
      left = center - basePillWidth / 2.0;
      right = center + basePillWidth / 2.0;
    } else if (_toSlot > _fromSlot) {
      // Moving right: leading (right) edge streams ahead, trailing (left) follows
      final headT = Curves.easeOutCubic.transform(t);
      final tailT = Curves.easeInOutCubic.transform(t);

      final startHead = (_fromSlot + 0.5) * slotWidth + basePillWidth / 2.0;
      final endHead = (_toSlot + 0.5) * slotWidth + basePillWidth / 2.0;
      final startTail = (_fromSlot + 0.5) * slotWidth - basePillWidth / 2.0;
      final endTail = (_toSlot + 0.5) * slotWidth - basePillWidth / 2.0;

      right = startHead + (endHead - startHead) * headT;
      left = startTail + (endTail - startTail) * tailT;
    } else {
      // Moving left: leading (left) edge streams ahead, trailing (right) follows
      final headT = Curves.easeOutCubic.transform(t);
      final tailT = Curves.easeInOutCubic.transform(t);

      final startHead = (_fromSlot + 0.5) * slotWidth - basePillWidth / 2.0;
      final endHead = (_toSlot + 0.5) * slotWidth - basePillWidth / 2.0;
      final startTail = (_fromSlot + 0.5) * slotWidth + basePillWidth / 2.0;
      final endTail = (_toSlot + 0.5) * slotWidth + basePillWidth / 2.0;

      left = startHead + (endHead - startHead) * headT;
      right = startTail + (endTail - startTail) * tailT;
    }

    final rawWidth = right - left;
    final currentWidth = math.max(basePillWidth * 0.85, rawWidth);
    final stretch = currentWidth / basePillWidth;

    // Fluid volume conservation: vertically narrows during horizontal stretch
    final currentHeight = math.max(
      28.0,
      basePillHeight / math.sqrt(math.min(stretch, 2.5)),
    );
    final top = centerY - currentHeight / 2.0;
    final currentCenterX = (left + right) / 2.0;

    return Positioned(
      left: currentCenterX - currentWidth / 2.0,
      top: top,
      width: currentWidth,
      height: currentHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                activeColor.withValues(alpha: isDark ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(currentHeight / 2.0),
            border: Border.all(
              color: activeColor.withValues(alpha: isDark ? 0.34 : 0.22),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final selectedIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: colors.background,
      body: widget.navigationShell,
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
                    child: SizedBox(
                      height: 56,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.maxWidth;
                          final totalHeight = constraints.maxHeight;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Fluid liquid transfer indicator that flows across the bar
                              AnimatedBuilder(
                                animation: _liquidTransferController,
                                builder: (context, _) {
                                  return _buildLiquidTransferPill(
                                    totalWidth: totalWidth,
                                    totalHeight: totalHeight,
                                    activeColor: colors.primary,
                                    isDark: isDark,
                                  );
                                },
                              ),
                              // 2. Row of nav items and center pay button
                              Row(
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
                                          key: const Key(
                                              'navbar_center_action_button'),
                                          onTap: () =>
                                              PayActionSheet.show(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _LiquidNavItem(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      activeIcon:
                                          Icons.account_balance_wallet_rounded,
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
                            ],
                          );
                        },
                      ),
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
                  const SizedBox(height: 3),
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
                ],
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
