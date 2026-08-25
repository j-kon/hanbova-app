import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _glowScale;
  late final Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _glowScale = Tween<double>(begin: 0.7, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.85, curve: Curves.easeInOut),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _barProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Branded transition duration
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted || GoRouter.maybeOf(context) == null) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.deepForest : AppColors.warmCream;
    final primaryAccent = isDark ? AppColors.leafGreen : AppColors.forestGreen;
    final textSecondary =
        isDark ? const Color(0xFFB0C4B8) : AppColors.softCharcoal;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Radial Glow
          AnimatedBuilder(
            animation: _glowScale,
            builder: (context, _) {
              return Transform.scale(
                scale: _glowScale.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryAccent.withValues(alpha: isDark ? 0.18 : 0.08),
                        backgroundColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Centered Logo and Tagline
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: isDark
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/branding/hanbova_icon_EXACT_MASTER.png',
                                width: 42,
                                height: 42,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Hanbova',
                                style: AppTypography.display.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  fontSize: 32,
                                ),
                              ),
                            ],
                          )
                        : Image.asset(
                            'assets/branding/hanbova_logo_EXACT_MASTER.png',
                            width: 210,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Send protected.',
                      style: AppTypography.titleMedium.copyWith(
                        color: textSecondary,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Subtle Animated Progress Bar Indicator
          Positioned(
            bottom: 48,
            child: FadeTransition(
              opacity: _taglineFade,
              child: AnimatedBuilder(
                animation: _barProgress,
                builder: (context, _) {
                  return Container(
                    width: 64,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.ribbonGreen.withValues(alpha: 0.5)
                          : const Color(0xFFE5E0D5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _barProgress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
