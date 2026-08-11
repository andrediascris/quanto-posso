import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Etapa $currentStep de $totalSteps',
      value: '$currentStep de $totalSteps',
      child: Row(
        children: [
          for (var step = 1; step <= totalSteps; step++) ...[
            Expanded(
              child: Container(
                height: AppSpacing.xxs,
                decoration: BoxDecoration(
                  color: step == currentStep
                      ? AppColors.accent
                      : step < currentStep
                      ? colorScheme.primary
                      : colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
              ),
            ),
            if (step < totalSteps) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
