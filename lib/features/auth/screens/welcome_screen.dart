import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WelcomeScreen extends StatefulWidget {
  final int initialSlide;
  const WelcomeScreen({super.key, this.initialSlide = 0});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSlide;
    _pageController = PageController(initialPage: widget.initialSlide);
  }

  @override
  void didUpdateWidget(covariant WelcomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlide != widget.initialSlide) {
      _currentPage = widget.initialSlide;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.initialSlide);
      }
    }
  }

  final List<Map<String, String>> _slides = [
    {
      'title': 'Send instantly.',
      'body': 'Fast Bitcoin payments for everyday life.',
      'image': 'assets/branding/onboarding/onboarding_01_instant.png',
    },
    {
      'title': 'Send protected.',
      'body': 'Add a protection window and stay in control.',
      'image': 'assets/branding/onboarding/onboarding_02_protected.png',
    },
    {
      'title': 'Built for Africa.',
      'body': 'Private, modern money for everyday people.',
      'image': 'assets/branding/onboarding/onboarding_03_africa.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.push('/signup');
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. Full Screen Background Onboarding Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Production Photograph Background
                  Image.asset(
                    slide['image']!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(color: colors.background),
                  ),

                  // Rich Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.background.withValues(alpha: 0.65),
                          colors.background.withValues(alpha: 0.25),
                          colors.background.withValues(alpha: 0.85),
                          colors.background,
                        ],
                        stops: const [0.0, 0.25, 0.60, 0.82],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Foreground Content UI
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar (Logo + Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/branding/hanbova_icon_EXACT_MASTER.png',
                            width: 34,
                            height: 34,
                            errorBuilder: (_, __, ___) => Icon(Icons.shield_outlined, color: colors.primary, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hanbova',
                                style: AppTypography.titleMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Send protected.',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.leafGreen : AppColors.forestGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_currentPage < _slides.length - 1)
                        TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Skip'),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Content Card (Title, Body, Dots, Buttons)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Slide Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _slides[_currentPage]['title']!,
                          key: ValueKey('title_$_currentPage'),
                          style: AppTypography.display.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Slide Body Description
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _slides[_currentPage]['body']!,
                          key: ValueKey('body_$_currentPage'),
                          style: AppTypography.bodyLarge.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Pagination Dots & Next Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              _slides.length,
                              (dotIndex) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 8),
                                width: _currentPage == dotIndex ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == dotIndex
                                      ? colors.primary
                                      : colors.border.withValues(alpha: 0.8),
                                  borderRadius: AppRadius.pillRadius,
                                ),
                              ),
                            ),
                          ),
                          if (_currentPage < _slides.length - 1)
                            IconButton(
                              onPressed: _next,
                              icon: Icon(Icons.arrow_forward_rounded, color: colors.primary, size: 20),
                              tooltip: 'Next',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Action Buttons
                      ElevatedButton(
                        onPressed: _currentPage == _slides.length - 1
                            ? () => context.push('/signup')
                            : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: isDark ? AppColors.deepForest : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.deepForest : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/signup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(color: colors.border, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                              ),
                              child: const Text('Create account'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(color: colors.border, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                              ),
                              child: const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Legal Disclaimer
                      Text(
                        'By continuing, you agree to Hanbova Terms and Privacy Policy.',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textTertiary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
