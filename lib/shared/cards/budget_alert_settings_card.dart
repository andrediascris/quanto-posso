import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';

class BudgetAlertSettingsCard extends StatelessWidget {
  const BudgetAlertSettingsCard({
    super.key,
    required this.enabled,
    required this.thresholdPercentage,
    required this.isLoading,
    required this.onEnabledChanged,
    required this.onThresholdChanged,
  });

  final bool enabled;
  final int thresholdPercentage;
  final bool isLoading;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onThresholdChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: radius,
        boxShadow: const [AppShadows.card],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alerta de limite',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Receba um aviso quando seus gastos se aproximarem '
                          'da sua renda.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Switch(
                    value: enabled,
                    onChanged: isLoading ? null : onEnabledChanged,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              IgnorePointer(
                ignoring: !enabled || isLoading,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 70, label: Text('70%')),
                      ButtonSegment(value: 80, label: Text('80%')),
                      ButtonSegment(value: 90, label: Text('90%')),
                    ],
                    selected: {thresholdPercentage},
                    onSelectionChanged: (selection) =>
                        onThresholdChanged(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Você será avisado ao atingir $thresholdPercentage% e '
                'novamente ao atingir 100%.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
