import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';

class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  final IconData selectedIcon;
  final ValueChanged<IconData> onSelected;

  static const icons = <IconData>[
    Icons.restaurant_rounded,
    Icons.shopping_cart_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.water_drop_rounded,
    Icons.lightbulb_rounded,
    Icons.wifi_rounded,
    Icons.health_and_safety_rounded,
    Icons.sports_esports_rounded,
    Icons.credit_card_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.checkroom_rounded,
    Icons.phone_android_rounded,
    Icons.receipt_long_rounded,
    Icons.work_rounded,
    Icons.child_care_rounded,
    Icons.build_rounded,
    Icons.more_horiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final icon = icons[index];
        final selected = icon.codePoint == selectedIcon.codePoint;
        return Semantics(
          button: true,
          selected: selected,
          label: 'Selecionar ícone ${index + 1}',
          child: Material(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: InkWell(
              onTap: () => onSelected(icon),
              borderRadius: BorderRadius.circular(AppRadius.circular),
              child: Icon(
                icon,
                color: selected ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
