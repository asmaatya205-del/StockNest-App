import 'package:flutter/material.dart';

/// StockNest Design System — Single source of truth for all colors.
/// Every widget imports this. Never hardcode a color anywhere else.
abstract class AppColors {
  // ── Brand Palette ──────────────────────────────────────────────
  static const Color primary        = Color(0xFF4F6EF7); // Vivid indigo-blue
  static const Color primaryLight   = Color(0xFF7B93FF);
  static const Color primaryDark    = Color(0xFF2D4ED8);
  static const Color primarySurface = Color(0xFFEEF1FF); // Very light tint

  static const Color secondary      = Color(0xFF00C896); // Mint-green accent
  static const Color secondaryLight = Color(0xFF5DFFC8);
  static const Color secondarySurface = Color(0xFFE6FBF5);

  static const Color accent         = Color(0xFFFF7043); // Warm coral CTA
  static const Color accentLight    = Color(0xFFFF9A7A);
  static const Color accentSurface  = Color(0xFFFFF0EB);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerSurface  = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF3B82F6);
  static const Color infoSurface    = Color(0xFFEFF6FF);

  // ── Neutrals (Light Mode) ──────────────────────────────────────
  static const Color background     = Color(0xFFF8F9FF); // Slight blue tint
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3FB);
  static const Color border         = Color(0xFFE4E8F4);
  static const Color borderLight    = Color(0xFFF0F2FA);

  static const Color textPrimary    = Color(0xFF0D1340);
  static const Color textSecondary  = Color(0xFF5A6490);
  static const Color textHint       = Color(0xFFA0ABCE);
  static const Color textOnDark     = Color(0xFFFFFFFF);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // ── Gradient Presets ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D4ED8), Color(0xFF4F6EF7), Color(0xFF7B93FF)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F6EF7), Color(0xFF6B8AFF)],
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF00A878)],
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7043), Color(0xFFFF4081)],
  );

  // Onboarding page gradients
  static const List<LinearGradient> onboardingGradients = [
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF00A878), Color(0xFF0EA5E9)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF7043), Color(0xFFFF4081)],
    ),
  ];
}