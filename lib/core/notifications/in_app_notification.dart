import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum InAppNotificationType { incoming, outgoing, protected, success, info }

class InAppNotificationModel {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final InAppNotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  InAppNotificationModel({
    String? id,
    required this.title,
    required this.message,
    this.icon = Icons.notifications_rounded,
    this.iconColor,
    this.type = InAppNotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onTap,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

final inAppNotificationProvider =
    StateNotifierProvider<InAppNotificationNotifier, InAppNotificationModel?>(
        (ref) {
  return InAppNotificationNotifier();
});

class InAppNotificationNotifier
    extends StateNotifier<InAppNotificationModel?> {
  Timer? _dismissTimer;

  InAppNotificationNotifier() : super(null);

  void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_rounded,
    Color? iconColor,
    InAppNotificationType type = InAppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _dismissTimer?.cancel();
    state = InAppNotificationModel(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      type: type,
      duration: duration,
      onTap: onTap,
    );

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}

class InAppNotificationOverlay extends ConsumerStatefulWidget {
  const InAppNotificationOverlay({super.key});

  @override
  ConsumerState<InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState
    extends ConsumerState<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  InAppNotificationModel? _currentNotification;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = ref.watch(inAppNotificationProvider);

    if (notification != null && notification != _currentNotification) {
      _currentNotification = notification;
      _progressController.duration = notification.duration;
      _progressController.forward(from: 0.0);
    } else if (notification == null) {
      _currentNotification = null;
      _progressController.reset();
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: notification == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(notification.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      notification.onTap?.call();
                      ref.read(inAppNotificationProvider.notifier).dismiss();
                    },
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < 0) {
                        ref.read(inAppNotificationProvider.notifier).dismiss();
                      }
                    },
                    child: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: AppRadius.lgRadius,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceCard,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(
                            color: _getAccentColor(notification, colors)
                                .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: AppShadows.card(context),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm + 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _getAccentColor(
                                              notification, colors)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      notification.icon,
                                      color: _getAccentColor(
                                          notification, colors),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.title,
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          notification.message,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: colors.textSecondary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colors.textTertiary,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => ref
                                        .read(inAppNotificationProvider
                                            .notifier)
                                        .dismiss(),
                                  ),
                                ],
                              ),
                            ),
                            // Subtle progress countdown bar at bottom of card
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return LinearProgressIndicator(
                                  value: 1.0 - _progressController.value,
                                  minHeight: 2.5,
                                  backgroundColor: colors.border
                                      .withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getAccentColor(notification, colors),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Color _getAccentColor(
      InAppNotificationModel notification, HanbovaColors colors) {
    if (notification.iconColor != null) {
      return notification.iconColor!;
    }
    switch (notification.type) {
      case InAppNotificationType.incoming:
        return colors.incoming;
      case InAppNotificationType.outgoing:
        return colors.outgoing;
      case InAppNotificationType.protected:
        return colors.protected;
      case InAppNotificationType.success:
        return colors.success;
      case InAppNotificationType.info:
        return colors.primary;
    }
  }
}
