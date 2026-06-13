import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Logo animation variables (Fade + Smooth slide up)
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;

  // Tagline animation variables (Delayed fade + slide up)
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 1. Logo Animation Timings
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    // 2. Tagline Animation Timings
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
    _navigate();
  }

  /// Evaluates authentication state properties and handles application routing.
  /// Determines whether to route towards dashboard screens, onboarding slides, or login portals.
  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Navigation Switch: Controls localized routing depending on user session states
    if (auth.isAuthenticated) {
      context.goNamed('home');
    } else if (auth.isFirstTime) {
      context.goNamed('onboarding');
    } else {
      context.goNamed('login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🎨 Premium Light & Clean Background Canvas Configuration
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF4F7FA),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand Logo Animated Component ──
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Image.asset(
                      'assets/images/logo_full.png',
                      width: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Subtitle / Tagline Animated Component ──
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      'Smart Factory & Warehouse Management',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium?.copyWith(
                        color: const Color(0xFF4A5568),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}