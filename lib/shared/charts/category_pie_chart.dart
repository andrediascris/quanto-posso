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
          ..sort((first, second) => second.value.compareTo(first.value));
    final visibleEntries = entries.take(8).toList(growable: false);

    if (visibleEntries.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nenhum gasto neste mês.',
            style: AppTypography.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final total = visibleEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    return Semantics(
      label:
          'Gráfico de gastos por categoria. '
          '${visibleEntries.length} categorias, '
          'total ${CurrencyUtils.format(total)}.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 42,
                child: _CategoryDonut(
                  entries: visibleEntries,
                  colorFor: _categoryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 58,
                child: _CategoryLegend(
                  entries: visibleEntries,
                  total: total,
                  nameFor: _categoryName,
                  colorFor: _categoryColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _categoryName(String id) {
    for (final category in categories) {
      if (category.id == id) return category.name;
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

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.entries, required this.colorFor});

  final List<MapEntry<String, double>> entries;
  final Color Function(String id) colorFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = constraints.constrainWidth(AppSpacing.xxl * 5);
        return Center(
          child: SizedBox(
            width: chartSize,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: chartSize / 5,
                  sectionsSpace: AppSpacing.xxs,
                  sections: [
                    for (final entry in entries)
                      PieChartSectionData(
                        value: entry.value,
                        color: colorFor(entry.key),
                        radius: chartSize / 4,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.entries,
    required this.total,
    required this.nameFor,
    required this.colorFor,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final String Function(String id) nameFor;
  final Color Function(String id) colorFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          Row(
            children: [
              Icon(
                Icons.circle,
                size: AppSpacing.xs,
                color: colorFor(entries[index].key),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  nameFor(entries[index].key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyUtils.format(entries[index].value),
                    maxLines: 1,
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '${(entries[index].value / total * 100).round()}%',
                style: AppTypography.small.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (index < entries.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
