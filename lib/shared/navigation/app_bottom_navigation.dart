import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddExpense,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : AppColors.surfaceLight;

    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.buttonHeight + AppSpacing.sm,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                top: AppSpacing.sm,
                child: Row(
                  children: [
                    _NavigationIcon(
                      label: 'Home',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      selected: currentIndex == 0,
                      onPressed: () => onDestinationSelected(0),
                    ),
                    _NavigationIcon(
                      label: 'Dashboard',
                      icon: Icons.pie_chart_outline_rounded,
                      selectedIcon: Icons.pie_chart_rounded,
                      selected: currentIndex == 1,
                      onPressed: () => onDestinationSelected(1),
                    ),
                    const Expanded(child: SizedBox()),
                    _NavigationIcon(
                      label: 'Histórico',
                      icon: Icons.receipt_long_outlined,
                      selectedIcon: Icons.receipt_long_rounded,
                      selected: currentIndex == 2,
                      onPressed: () => onDestinationSelected(2),
                    ),
                    _NavigationIcon(
                      label: 'Configurações',
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                      selected: currentIndex == 3,
                      onPressed: () => onDestinationSelected(3),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Tooltip(
                  message: 'Adicionar gasto',
                  child: Semantics(
                    button: true,
                    label: 'Adicionar gasto',
                    child: Container(
                      width: AppSpacing.buttonHeight,
                      height: AppSpacing.buttonHeight,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [AppShadows.button],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onAddExpense,
                          customBorder: const CircleBorder(),
                          child: const Icon(
                            Icons.add_rounded,
                            size: AppSpacing.xl,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final iconColor = selected
        ? (isDark ? colorScheme.secondary : AppColors.primary)
        : colorScheme.onSurfaceVariant;
    final backgroundColor = selected
        ? AppColors.accent.withValues(alpha: isDark ? 0.22 : 0.28)
        : Colors.transparent;

    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: AppSpacing.lg,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
