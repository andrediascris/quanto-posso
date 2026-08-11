import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(AppRadius.medium);
    final defaultBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: isDark ? colorScheme.outline : AppColors.border,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.error),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: obscureText,
      enabled: enabled,
      style: AppTypography.body.copyWith(
        color: isDark ? colorScheme.onSurface : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: isDark
                    ? colorScheme.onSurfaceVariant
                    : AppColors.primary,
              ),
        prefixText: prefixText,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        labelStyle: AppTypography.body.copyWith(
          color: isDark ? colorScheme.onSurfaceVariant : AppColors.textPrimary,
        ),
        hintStyle: AppTypography.body.copyWith(
          color: isDark
              ? colorScheme.onSurfaceVariant
              : AppColors.textSecondary,
        ),
        prefixStyle: AppTypography.body.copyWith(
          color: isDark ? colorScheme.onSurface : AppColors.textPrimary,
        ),
        fillColor: isDark ? colorScheme.surfaceContainerHigh : null,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: isDark ? colorScheme.primary : AppColors.primary,
          ),
        ),
        border: defaultBorder,
        enabledBorder: defaultBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
      ),
    );
  }
}
