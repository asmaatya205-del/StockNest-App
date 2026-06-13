import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Ghost button — transparent background, colored border + label.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}