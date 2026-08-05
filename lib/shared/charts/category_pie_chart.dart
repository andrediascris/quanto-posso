import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense_category.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.totalsByCategory,
    required this.categories,
  });

  final Map<String, double> totalsByCategory;
  final List<ExpenseCategory> categories;

  @override
  Widget build(BuildContext context) {
    final entries =
        totalsByCategory.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nenhum gasto neste mês.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Semantics(
      label:
          'Gráfico de gastos por categoria. '
          '${entries.length} categorias, total ${CurrencyUtils.format(total)}.',
      child: Column(
        children: [
          SizedBox(
            height: AppSpacing.xxxl * 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: AppSpacing.xl,
                    sectionsSpace: AppSpacing.xxs,
                    sections: [
                      for (var index = 0; index < entries.length; index++)
                        PieChartSectionData(
                          value: entries[index].value,
                          color: _categoryColor(entries[index].key),
                          radius: AppSpacing.xl,
                          title: entries[index].value / total >= 0.08
                              ? '${(entries[index].value / total * 100).round()}%'
                              : '',
                          titleStyle: AppTypography.small.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'Categorias',
                  style: AppTypography.small.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < entries.length; index++) ...[
            Row(
              children: [
                Icon(Icons.circle, color: _categoryColor(entries[index].key)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _categoryName(entries[index].key),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${CurrencyUtils.format(entries[index].value)} · '
                  '${(entries[index].value / total * 100).toStringAsFixed(1)}%',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (index < entries.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  String _categoryName(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return 'Outros';
  }

  Color _categoryColor(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
            ? Color(category.colorValue)
            : AppColors.primary;
      }
    }
    return AppColors.primary;
  }
}
