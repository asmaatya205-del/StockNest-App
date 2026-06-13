import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_nest/core/theme/app_colors.dart';
import 'package:stock_nest/core/theme/app_spacing.dart';
import 'package:stock_nest/core/theme/app_text_styles.dart';

/// Shell widget that wraps all main screens with the Bottom Nav Bar.
/// The [child] is the current active screen managed globally by GoRouter.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Global Navigation Core Configurations List Map
  static const List<_NavItem> _items = [
    _NavItem(
      label:      'Home',
      icon:       Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      path:       '/home',
    ),
    _NavItem(
      label:      'Warehouses',
      icon:       Icons.warehouse_outlined,
      activeIcon: Icons.warehouse_rounded,
      path:       '/warehouses',
    ),
    _NavItem(
      label:      'Products',
      icon:       Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      path:       '/products',
    ),
    _NavItem(
      label:      'Logs',
      icon:       Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      path:       '/logs',
    ),
    _NavItem(
      label:      'Settings',
      icon:       Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      path:       '/settings',
    ),
  ];

  /// Resolves the current active index by checking if the active
  /// GoRouter location starts with any of the defined bottom item paths.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      // Key configuration to prevent viewport shifting when keyboards pop up
      resizeToAvoidBottomInset: false,
      body: child,
      bottomNavigationBar: _BottomNav(
        items:        _items,
        currentIndex: currentIndex,
        onTap: (i) => context.go(_items[i].path),
      ),
    );
  }
}

// ── Bottom Nav Component Wrapper ───────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Ensures safe padded layouts on bezel-less screen platforms
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavTab(
                  item:     items[i],
                  isActive: i == currentIndex,
                  onTap:    () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tab Component Item ──────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final _NavItem     item;
  final bool         isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Enforces immediate hit testing across empty zones
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Pill Indicator background shape container mapping M3 guidelines
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical:   AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primarySurface
                  : Colors.transparent,
              borderRadius: AppRadius.chipRadius,
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
          ),

          // Label text segment embedded inside dynamic sizing blocks to hide/reveal smoothly
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.0,
              child: isActive
                  ? Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  item.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize:   11,
                  ),
                ),
              )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Item Blueprint Data Structure Model ──────────────────────────────────

class _NavItem {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  final String   path;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}