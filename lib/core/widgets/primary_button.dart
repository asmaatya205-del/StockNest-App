import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A gradient CTA button used throughout the app.
/// Accepts a label, optional icon, loading state, and callbacks.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool useAccent; // coral gradient instead of blue
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.useAccent = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = useAccent
        ? AppColors.cardGradient3
        : AppColors.primaryGradient;

    final shadow = useAccent ? AppShadows.buttonAccent : AppShadows.button;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? AppColors.border : null,
        borderRadius: AppRadius.buttonRadius,
        boxShadow: onPressed == null ? [] : shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadius.buttonRadius,
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.textOnDark),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.textOnDark, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelLargeOnDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
