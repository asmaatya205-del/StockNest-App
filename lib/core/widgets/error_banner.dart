import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.danger),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: AppColors.danger, size: 18),
          ),
        ],
      ),
    );
  }
}