import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';

class AnnualSummaryCard extends StatelessWidget {
  const AnnualSummaryCard({
    super.key,
    required this.year,
    required this.total,
    required this.monthlyAverage,
    required this.expenseCount,
  });

  final int year;
  final double total;
  final double monthlyAverage;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumo de $year',
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AnnualValue(
            label: 'Total no ano',
            value: CurrencyUtils.format(total),
          ),
          const SizedBox(height: AppSpacing.md),
          _AnnualValue(
            label: 'Média mensal',
            value: CurrencyUtils.format(monthlyAverage),
          ),
          const SizedBox(height: AppSpacing.md),
          _AnnualValue(
            label: 'Quantidade de gastos',
            value: expenseCount.toString(),
          ),
        ],
      ),
    );
  }
}

class _AnnualValue extends StatelessWidget {
  const _AnnualValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
