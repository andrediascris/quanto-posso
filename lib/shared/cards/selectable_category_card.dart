import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';

class SelectableCategoryCard extends StatelessWidget {
  const SelectableCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.card);
    final backgroundColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.16)
        : colorScheme.surfaceContainer;
    final iconColor = isSelected ? AppColors.accent : colorScheme.primary;
    final textColor = colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected ? AppColors.accent : colorScheme.outline,
          ),
          boxShadow: isSelected ? const [AppShadows.card] : AppShadows.none,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
