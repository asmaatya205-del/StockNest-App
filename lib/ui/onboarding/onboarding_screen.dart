import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../domain/providers/auth_provider.dart'; // Imported to bridge local configuration states
import 'onboarding_page_data.dart';
import 'onboarding_slide.dart';

/// Onboarding screen — manages the PageView state and bottom controls.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = OnboardingPageData.pages;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  /// Evaluates sliding checkpoints and triggers programmatic registration layout transitions
  void _nextPage() {
    if (_isLastPage) {
      _completeAndNavigate('register');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Hydrates persistence stores before clearing onboarding constraints
  Future<void> _completeAndNavigate(String routeName) async {
    // 1. Commits onboarding completion globally inside AuthProvider state buffers
    await context.read<AuthProvider>().completeOnboarding();

    // 2. Dispatches explicit route update triggers now that the guard state evaluates to false
    if (mounted) {
      context.goNamed(routeName);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // ── Slides Viewport Region ─────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => OnboardingSlide(data: _pages[i]),
          ),

          // ── Bottom Panel Viewport Overlay Controls ───────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              currentPage: _currentPage,
              pageCount: _pages.length,
              isLastPage: _isLastPage,
              activeDotColor: currentData.dotColor,
              onNext: _nextPage,
              onSkip: () => _completeAndNavigate('login'),
              onLogin: () => _completeAndNavigate('login'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom controls panel — dots + CTA + skip/login.
/// Extracted to keep OnboardingScreen readable.
class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final Color activeDotColor;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onLogin;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.activeDotColor,
    required this.onNext,
    required this.onSkip,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.25),
            Colors.black.withOpacity(0.45),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Discrete layout dot tracking indexes
          PageDots(
            count: pageCount,
            current: currentPage,
            activeColor: activeDotColor,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Central operational action switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: PrimaryButton(
              key: ValueKey(isLastPage),
              label: isLastPage ? 'Get Started' : 'Continue',
              onPressed: onNext,
              icon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              useAccent: isLastPage,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Fallback skip or authorization gateway selection panels
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLastPage
                ? _LoginRow(onLogin: onLogin)
                : TextButton(
              key: const ValueKey('skip'),
              onPressed: onSkip,
              child: Text(
                'Skip for now',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRow extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginRow({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        GestureDetector(
          onTap: onLogin,
          child: Text(
            'Log in',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}