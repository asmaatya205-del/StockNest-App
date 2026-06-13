import 'package:flutter/material.dart';

/// Animated dot indicators for page position.
/// Reusable in any multi-page flow.
class PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  const PageDots({
    super.key,
    required this.count,
    required this.current,
    required this.activeColor,
    this.inactiveColor = const Color(0x40FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}