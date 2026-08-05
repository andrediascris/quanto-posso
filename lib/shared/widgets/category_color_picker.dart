import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';

class CategoryColorPicker extends StatelessWidget {
  const CategoryColorPicker({
    super.key,
    required this.selectedColorValue,
    required this.onSelected,
  });

  final int selectedColorValue;
  final ValueChanged<int> onSelected;

  static const colors = <int>[
    0xFF1D1B4F,
    0xFFF9A826,
    0xFF2ECC71,
    0xFFF4B400,
    0xFFE74C3C,
    0xFF3498DB,
    0xFF7E57C2,
    0xFF26A69A,
    0xFFEC407A,
    0xFF8D6E63,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < colors.length; index++)
          _ColorOption(
            colorValue: colors[index],
            selected: colors[index] == selectedColorValue,
            label: 'Selecionar cor ${index + 1}',
            onTap: () => onSelected(colors[index]),
          ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.colorValue,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox.square(
        dimension: AppSpacing.xxxl,
        child: Material(
          color: Color(colorValue),
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: selected
                ? const Icon(Icons.check_rounded, color: AppColors.textLight)
                : null,
          ),
        ),
      ),
    );
  }
}
