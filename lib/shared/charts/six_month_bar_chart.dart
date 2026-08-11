import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';

class SixMonthBarChart extends StatelessWidget {
  const SixMonthBarChart({super.key, required this.summaries})
    : assert(summaries.length == 6);

  final List<MonthlyExpenseSummary> summaries;

  static const _shortMonthNames = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    final maximum = summaries.fold<double>(
      0,
      (value, summary) => math.max(value, summary.total),
    );
    final semanticSummary = summaries
        .map(
          (summary) =>
              '${_monthNames[summary.month.month - 1]}: '
              '${CurrencyUtils.format(summary.total)}, '
              '${summary.expenseCount} gastos',
        )
        .join('. ');

    return Semantics(
      label: 'Evolução dos últimos 6 meses. $semanticSummary.',
      child: SizedBox(
        height: AppSpacing.xxxl * 5,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maximum == 0 ? 1 : maximum * 1.2,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context).colorScheme.outline,
                strokeWidth: AppSpacing.xxs / 4,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: AppSpacing.xl,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= summaries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _shortMonthNames[summaries[index].month.month - 1],
                        style: AppTypography.small.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: AppSpacing.xxl,
                  getTitlesWidget: (value, meta) => Text(
                    _compactValue(value),
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final summary = summaries[group.x];
                  return BarTooltipItem(
                    '${_monthNames[summary.month.month - 1]} '
                    '${summary.month.year}\n'
                    '${CurrencyUtils.format(summary.total)}\n'
                    '${summary.expenseCount} gastos',
                    AppTypography.small.copyWith(color: AppColors.textLight),
                  );
                },
              ),
            ),
            barGroups: [
              for (var index = 0; index < summaries.length; index++)
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: summaries[index].total,
                      width: AppSpacing.md,
                      color: index == summaries.length - 1
                          ? AppColors.accent
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.small),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
