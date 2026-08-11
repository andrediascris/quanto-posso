import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';

class MonthlyExpenseLineChart extends StatelessWidget {
  const MonthlyExpenseLineChart({
    super.key,
    required this.dailyTotals,
    required this.month,
  });

  final List<DailyExpenseTotal> dailyTotals;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (dailyTotals.isEmpty) {
      return Text(
        'Ainda não há evolução de gastos neste mês.',
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final totalsByDay = {
      for (final item in dailyTotals) item.day.day: item.total,
    };
    final spots = [
      for (var day = 1; day <= lastDay; day++)
        FlSpot(day.toDouble(), totalsByDay[day] ?? 0),
    ];
    final maxTotal = spots.fold<double>(
      0,
      (maximum, spot) => math.max(maximum, spot.y),
    );

    final monthlyTotal = dailyTotals.fold<double>(
      0,
      (total, item) => total + item.total,
    );
    final safeMaxY = maxTotal == 0 ? 1.0 : maxTotal * 1.20;
    final horizontalInterval = safeMaxY / 4;
    return Semantics(
      label:
          'Gráfico da evolução mensal de gastos. '
          'Total ${CurrencyUtils.format(monthlyTotal)}.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shownDays = constraints.maxWidth < 700
              ? <int>{1, 10, 20, lastDay}
              : <int>{1, 5, 10, 15, 20, 25, lastDay};
          return SizedBox(
            height: AppSpacing.xxxl * 4 + AppSpacing.xl,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: lastDay.toDouble(),
                minY: 0,
                maxY: safeMaxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
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
                      interval: 1,
                      reservedSize: AppSpacing.xl,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        if (!shownDays.contains(day) && day != lastDay) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '$day',
                          style: AppTypography.small.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: horizontalInterval,
                      reservedSize: AppSpacing.xxxl,
                      getTitlesWidget: (value, meta) => Text(
                        _compactValue(value),
                        style: AppTypography.small.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            '${DateFormat('dd/MM').format(DateTime(month.year, month.month, spot.x.toInt()))}\n'
                            '${CurrencyUtils.format(spot.y)}',
                            AppTypography.small.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: AppColors.accent,
                    isCurved: true,
                    barWidth: AppSpacing.xxs,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: AppSpacing.xxs,
                            color: AppColors.accent,
                            strokeWidth: 0,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

class SixMonthExpenseLineChart extends StatelessWidget {
  const SixMonthExpenseLineChart({super.key, required this.monthlyTotals});

  final List<MonthlyExpenseSummary> monthlyTotals;
  static const _monthLabels = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.isEmpty) {
      return Text(
        'Ainda não há evolução mensal disponível.',
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final spots = [
      for (var index = 0; index < monthlyTotals.length; index++)
        FlSpot(index.toDouble(), monthlyTotals[index].total),
    ];
    final maximum = spots.fold<double>(
      0,
      (value, spot) => math.max(value, spot.y),
    );
    final safeMaxY = maximum == 0 ? 1.0 : maximum * 1.20;
    final interval = safeMaxY / 4;
    final total = monthlyTotals.fold<double>(
      0,
      (value, summary) => value + summary.total,
    );
    return Semantics(
      label:
          'Gráfico da evolução dos últimos 6 meses. Total ${CurrencyUtils.format(total)}.',
      child: SizedBox(
        height: AppSpacing.xxxl * 4 + AppSpacing.xl,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, spots.length - 1).toDouble(),
            minY: 0,
            maxY: safeMaxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
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
                  interval: 1,
                  reservedSize: AppSpacing.xl,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= monthlyTotals.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      _monthLabels[monthlyTotals[index].month.month - 1],
                      style: AppTypography.small.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: AppSpacing.xxxl,
                  getTitlesWidget: (value, meta) => Text(
                    _compactMonthlyValue(value),
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final summary = monthlyTotals[spot.x.toInt()];
                  return LineTooltipItem(
                    '${_monthLabels[summary.month.month - 1]}/${summary.month.year}\n'
                    '${CurrencyUtils.format(summary.total)}',
                    AppTypography.small.copyWith(color: AppColors.textLight),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: AppColors.accent,
                isCurved: true,
                barWidth: AppSpacing.xxs,
                dotData: FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: AppSpacing.xxs,
                        color: AppColors.accent,
                        strokeWidth: 0,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactMonthlyValue(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
