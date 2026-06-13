import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Data for a single onboarding page.
/// Pure data — no UI logic.
class OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color dotColor;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.dotColor,
  });

  /// The three onboarding pages for StockNest.
  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Manage Your\nWarehouses',
      subtitle:
      'Create unlimited warehouses with nested sub-warehouses. Organize your inventory exactly the way your business works.',
      icon: Icons.warehouse_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
      ),
      dotColor: AppColors.primaryLight,
    ),
    OnboardingPageData(
      title: 'Track Every\nProduct',
      subtitle:
      'Add products with SKU, category, and stock levels. Get instant alerts when inventory falls below your minimum threshold.',
      icon: Icons.inventory_2_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00A878), Color(0xFF0EA5E9)],
      ),
      dotColor: AppColors.secondary,
    ),
    OnboardingPageData(
      title: 'Distribute\nSmart',
      subtitle:
      'Move products across warehouses in seconds. Full distribution history and real-time quantity updates across your entire network.',
      icon: Icons.swap_horiz_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7043), Color(0xFFFF4081)],
      ),
      dotColor: AppColors.accent,
    ),
  ];
}