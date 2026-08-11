import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

class FakeDashboardExpenseRepository extends ExpenseRepository {
  FakeDashboardExpenseRepository({
    Map<String, double> totals = const {},
    this.categoryTotals = const {'food': 75},
    List<DailyExpenseTotal> dailyTotals = const [],
    this.throwOnLoad = false,
  }) : totals = Map.of(totals),
       dailyTotals = List.of(dailyTotals);

  final Map<String, double> totals;
  final Map<String, double> categoryTotals;
  final List<DailyExpenseTotal> dailyTotals;
  final bool throwOnLoad;
  int dailyLoadCount = 0;

  String _key(DateTime date) => '${date.year}-${date.month}';

  @override
  Future<double> getTotalBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    return totals[_key(start)] ?? 0;
  }

  @override
  Future<Map<String, double>> getTotalsByCategory({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    return Map.of(categoryTotals);
  }

  @override
  Future<List<DailyExpenseTotal>> getDailyTotalsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    dailyLoadCount++;
    return List.of(dailyTotals);
  }

  @override
  Future<List<MonthlyExpenseSummary>> getMonthlySummaries({
    required DateTime startMonth,
    required DateTime endMonth,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    final summaries = <MonthlyExpenseSummary>[];
    for (final entry in totals.entries) {
      final parts = entry.key.split('-');
      final month = DateTime(int.parse(parts.first), int.parse(parts.last));
      final start = DateTime(startMonth.year, startMonth.month);
      final end = DateTime(endMonth.year, endMonth.month);
      if (!month.isBefore(start) && !month.isAfter(end) && entry.value > 0) {
        summaries.add(
          MonthlyExpenseSummary(
            month: month,
            total: entry.value,
            expenseCount: 1,
          ),
        );
      }
    }
    return summaries;
  }

  @override
  Future<Expense?> getHighestExpenseBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    return null;
  }
}

void main() {
  final now = DateTime.now();
  final currentKey = '${now.year}-${now.month}';
  final previous = DateTime(now.year, now.month - 1);
  final previousKey = '${previous.year}-${previous.month}';
  final daily = [
    DailyExpenseTotal(day: DateTime(now.year, now.month, 2), total: 75),
  ];

  test('loadDashboard carrega todas as métricas', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(
        totals: {currentKey: 150, previousKey: 100},
        dailyTotals: daily,
      ),
    );

    await provider.loadDashboard();

    expect(provider.status, DashboardStatus.ready);
    expect(provider.currentMonthTotal, 150);
    expect(provider.previousMonthTotal, 100);
    expect(provider.totalsByCategory, {'food': 75});
    expect(provider.dailyTotals, daily);
  });

  test('comparisonPercentage calcula aumento', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(
        totals: {currentKey: 120, previousKey: 100},
      ),
    );
    await provider.loadDashboard();
    expect(provider.comparisonPercentage, 20);
  });

  test('comparisonPercentage calcula redução', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(
        totals: {currentKey: 80, previousKey: 100},
      ),
    );
    await provider.loadDashboard();
    expect(provider.comparisonPercentage, -20);
  });

  test('comparisonPercentage trata mês anterior zerado', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(totals: {currentKey: 50}),
    );
    await provider.loadDashboard();
    expect(provider.comparisonPercentage, 100);
  });

  test('dailyAverage usa os dias transcorridos no mês atual', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(
        totals: {currentKey: now.day * 10.0},
      ),
    );
    await provider.loadDashboard();
    expect(provider.dailyAverage, 10);
  });

  test('selectMonth altera o mês e recarrega', () async {
    final repository = FakeDashboardExpenseRepository();
    final provider = DashboardProvider(repository: repository);

    await provider.selectMonth(previous);

    expect(provider.selectedMonth, DateTime(previous.year, previous.month));
    expect(repository.dailyLoadCount, 1);
  });

  test('nextMonth não avança para o futuro', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(),
    );
    final selected = provider.selectedMonth;

    await provider.nextMonth();

    expect(provider.selectedMonth, selected);
    expect(provider.canGoToNextMonth, isFalse);
  });

  test('erro no repository define status e mensagem', () async {
    final provider = DashboardProvider(
      repository: FakeDashboardExpenseRepository(throwOnLoad: true),
    );

    await provider.loadDashboard();

    expect(provider.status, DashboardStatus.error);
    expect(provider.errorMessage, 'Não foi possível carregar o dashboard.');
  });
}
