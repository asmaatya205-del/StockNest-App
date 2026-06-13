import 'package:flutter/material.dart';
import 'app_colors.dart';

/// StockNest Typography System.
/// All text styles derive from one place — no duplication.
abstract class AppTextStyles {
  // ── Font Family ────────────────────────────────────────────────
  static const String _fontFamily = 'Poppins';

  // ── Display ───────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // ── Headlines ─────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.5,
  );

  // ── Labels ────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ── On-Dark variants (white text) ─────────────────────────────
  static TextStyle get displayLargeOnDark =>
      displayLarge.copyWith(color: AppColors.textOnDark);
  static TextStyle get displayMediumOnDark =>
      displayMedium.copyWith(color: AppColors.textOnDark);
  static TextStyle get headlineLargeOnDark =>
      headlineLarge.copyWith(color: AppColors.textOnDark);
  static TextStyle get bodyLargeOnDark =>
      bodyLarge.copyWith(color: AppColors.textOnDark.withOpacity(0.85));
  static TextStyle get bodyMediumOnDark =>
      bodyMedium.copyWith(color: AppColors.textOnDark.withOpacity(0.75));
  static TextStyle get labelLargeOnDark =>
      labelLarge.copyWith(color: AppColors.textOnDark);
}