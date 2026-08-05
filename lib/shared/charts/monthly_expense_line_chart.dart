import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';

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
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
    return Semantics(
      label:
          'Gráfico da evolução mensal de gastos. '
          'Total ${CurrencyUtils.format(monthlyTotal)}.',
      child: SizedBox(
        height: AppSpacing.xxxl * 5,
        child: LineChart(
          LineChartData(
            minX: 1,
            maxX: lastDay.toDouble(),
            minY: 0,
            maxY: maxTotal == 0 ? 1 : maxTotal * 1.15,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: AppColors.border,
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
                    const shownDays = {1, 5, 10, 15, 20, 25};
                    if (!shownDays.contains(day) && day != lastDay) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '$day',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary,
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
                color: AppColors.primary,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
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
