import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'onboarding_page_data.dart';

/// One visual slide in the onboarding carousel.
/// Stateless — only receives data.
class OnboardingSlide extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration card ─────────────────────────────
              _IllustrationCard(icon: data.icon, size: size.width * 0.62),

              const Spacer(flex: 2),

              // ── Text block ────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.displayMediumOnDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      data.subtitle,
                      style: AppTextStyles.bodyLargeOnDark,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating icon card with layered circles for depth.
class _IllustrationCard extends StatelessWidget {
  final IconData icon;
  final double size;

  const _IllustrationCard({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          // Mid ring
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          // Icon container
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: size * 0.26,
              color: Colors.white,
            ),
          ),

          // Decorative floating dots
          Positioned(
            top: size * 0.08,
            right: size * 0.12,
            child: _FloatingDot(size: 10),
          ),
          Positioned(
            bottom: size * 0.12,
            left: size * 0.08,
            child: _FloatingDot(size: 7),
          ),
          Positioned(
            top: size * 0.22,
            left: size * 0.05,
            child: _FloatingDot(size: 5),
          ),
        ],
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  final double size;
  const _FloatingDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.4),
      ),
    );
  }
}
