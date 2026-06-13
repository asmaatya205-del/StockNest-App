import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Branded text field used across all forms in StockNest.
/// Consistent look derived from AppTheme — no local color overrides.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? IconTheme(
          data: const IconThemeData(
            color: AppColors.textHint,
            size: 20,
          ),
          child: prefixIcon!,
        )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
          data: const IconThemeData(
            color: AppColors.textHint,
            size: 20,
          ),
          child: suffixIcon!,
        )
            : null,
      ),
    );
  }
}