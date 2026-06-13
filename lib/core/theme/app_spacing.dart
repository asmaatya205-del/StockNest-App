import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';

abstract class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;

  static const double pagePadding = 24.0;
}

abstract class AppRadius {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;
  static const double full = 100.0;

  static const BorderRadius cardRadius   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(full));
  static const BorderRadius inputRadius  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius   = BorderRadius.all(Radius.circular(full));
}

abstract class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color:       AppColors.primary.withOpacity(0.08),
      blurRadius:  20,
      offset:      const Offset(0, 4),
    ),
    BoxShadow(
      color:       Colors.black.withOpacity(0.04),
      blurRadius:  8,
      offset:      const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> button = [
    BoxShadow(
      color:      AppColors.primary.withOpacity(0.35),
      blurRadius: 16,
      offset:     const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> buttonAccent = [
    BoxShadow(
      color:      AppColors.accent.withOpacity(0.35),
      blurRadius: 16,
      offset:     const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> floating = [
    BoxShadow(
      color:      Colors.black.withOpacity(0.12),
      blurRadius: 32,
      offset:     const Offset(0, 8),
    ),
  ];
}