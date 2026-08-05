import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(AppRadius.button);

    return Semantics(
      button: true,
      label: label,
      enabled: isEnabled,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: Container(
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.accent : AppColors.disabled,
            borderRadius: borderRadius,
            boxShadow: const [AppShadows.button],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              borderRadius: borderRadius,
              child: Center(
                child: isLoading
                    ? const SizedBox.square(
                        dimension: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: AppSpacing.xxs,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            label,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
