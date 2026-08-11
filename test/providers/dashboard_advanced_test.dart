import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/dashboard_insight.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

class FakeAdvancedDashboardRepository extends ExpenseRepository {
  FakeAdvancedDashboardRepository({
    this.summaries = const [],
    this.categoryTotals = const {},
    this.highestExpense,
    this.throwOnLoad = false,
  });

  final List<MonthlyExpenseSummary> summaries;
  final Map<String, double> categoryTotals;
  final Expense? highestExpense;
  final bool throwOnLoad;
  int monthlySummaryLoads = 0;

  @override
  Future<List<MonthlyExpenseSummary>> getMonthlySummaries({
    required DateTime startMonth,
    required DateTime endMonth,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    monthlySummaryLoads++;
    final start = DateTime(startMonth.year, startMonth.month);
    final end = DateTime(endMonth.year, endMonth.month);
    return summaries
        .where(
          (summary) =>
              !summary.month.isBefore(start) && !summary.month.isAfter(end),
        )
        .toList(growable: false);
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
    return const [];
  }

  @override
  Future<Expense?> getHighestExpenseBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) throw StateError('Falha simulada');
    return highestExpense;
  }
}

void main() {
  final fixedNow = DateTime(2026, 8, 15, 18);
  final summaries = [
    MonthlyExpenseSummary(month: DateTime(2026, 1), total: 20, expenseCount: 1),
    MonthlyExpenseSummary(month: DateTime(2026, 3), total: 30, expenseCount: 1),
    MonthlyExpenseSummary(month: DateTime(2026, 5), total: 50, expenseCount: 2),
    MonthlyExpenseSummary(month: DateTime(2026, 7), total: 80, expenseCount: 2),
    MonthlyExpenseSummary(
      month: DateTime(2026, 8),
      total: 150,
      expenseCount: 3,
    ),
  ];
  final highest = Expense(
    id: 1,
    amount: 90,
    categoryId: 'food',
    description: 'Mercado',
    occurredAt: DateTime(2026, 8, 10),
    createdAt: fixedNow,
    updatedAt: fixedNow,
  );
  final category = ExpenseCategory(
    id: 'food',
    name: 'Alimentação',
    iconCodePoint: 0,
    iconFontFamily: 'MaterialIcons',
    colorValue: 0,
    isDefault: true,
    createdAt: fixedNow,
  );

  DashboardProvider buildProvider({
    List<MonthlyExpenseSummary>? monthlySummaries,
    Map<String, double> categoryTotals = const {'food': 100, 'market': 50},
    Expense? highestExpense,
    double income = 1000,
  }) {
    final provider = DashboardProvider(
      repository: FakeAdvancedDashboardRepository(
        summaries: monthlySummaries ?? summaries,
        categoryTotals: categoryTotals,
        highestExpense: highestExpense ?? highest,
      ),
      now: () => fixedNow,
    );
    provider.setFinancialContext(monthlyIncome: income, categories: [category]);
    return provider;
  }

  test('preenche seis meses incluindo meses com total zero', () async {
    final provider = buildProvider();
    await provider.loadDashboard();

    expect(provider.lastSixMonths, hasLength(6));
    expect(provider.lastSixMonths.map((item) => item.month.month), [
      3,
      4,
      5,
      6,
      7,
      8,
    ]);
    expect(provider.lastSixMonths.map((item) => item.total), [
      30,
      0,
      50,
      0,
      80,
      150,
    ]);
    expect(provider.lastSixMonths[1].expenseCount, 0);
  });

  test('calcula projeção do mês atual', () async {
    final provider = buildProvider();
    await provider.loadDashboard();
    expect(provider.projectedMonthlyTotal, 310);
  });

  test('não projeta incorretamente meses anteriores', () async {
    final provider = buildProvider();
    await provider.selectMonth(DateTime(2026, 7));
    expect(provider.projectedMonthlyTotal, 80);
  });

  test('encontra categoria principal sem depender da ordem do mapa', () async {
    final provider = buildProvider(
      categoryTotals: const {'market': 50, 'food': 100},
    );
    await provider.loadDashboard();
    expect(provider.topCategoryId, 'food');
    expect(provider.topCategoryTotal, 100);
  });

  test('encontra maior gasto individual', () async {
    final provider = buildProvider(highestExpense: highest);
    await provider.loadDashboard();
    expect(provider.highestExpense, same(highest));
  });

  test('calcula total e quantidade anual', () async {
    final provider = buildProvider();
    await provider.loadDashboard();
    expect(provider.annualTotal, 330);
    expect(provider.annualExpenseCount, 9);
  });

  test('calcula média anual pelos meses transcorridos', () async {
    final provider = buildProvider();
    await provider.loadDashboard();
    expect(provider.annualMonthlyAverage, 41.25);
  });

  test('calcula comparação mensal', () async {
    final provider = buildProvider();
    await provider.loadDashboard();
    expect(provider.comparisonPercentage, 87.5);
  });

  test('gera insight positivo quando o gasto diminui', () async {
    final provider = buildProvider(
      monthlySummaries: [
        MonthlyExpenseSummary(
          month: DateTime(2026, 7),
          total: 100,
          expenseCount: 1,
        ),
        MonthlyExpenseSummary(
          month: DateTime(2026, 8),
          total: 80,
          expenseCount: 1,
        ),
      ],
      categoryTotals: const {},
    );
    await provider.loadDashboard();
    expect(
      provider.insights.any(
        (insight) => insight.type == DashboardInsightType.positive,
      ),
      isTrue,
    );
  });

  test('gera insight de aumento superior a dez por cento', () async {
    final provider = buildProvider();
    await provider.loadDashboard();
    expect(
      provider.insights.any((insight) => insight.title == 'Atenção ao aumento'),
      isTrue,
    );
  });

  test('gera insight quando a projeção ultrapassa a renda', () async {
    final provider = buildProvider(income: 200);
    await provider.loadDashboard();
    expect(
      provider.insights.any(
        (insight) => insight.title == 'Projeção acima da renda',
      ),
      isTrue,
    );
  });

  test('limita insights a três e não repete títulos', () async {
    final provider = buildProvider(income: 200);
    await provider.loadDashboard();
    expect(provider.insights.length, lessThanOrEqualTo(3));
    expect(
      provider.insights.map((insight) => insight.title).toSet().length,
      provider.insights.length,
    );
  });

  test('evita divisão por zero em renda e totais vazios', () async {
    final provider = buildProvider(
      monthlySummaries: const [],
      categoryTotals: const {},
      income: 0,
    );
    await provider.loadDashboard();
    expect(provider.projectedMonthlyTotal, 0);
    expect(provider.incomeUsagePercentage, 0);
    expect(provider.annualMonthlyAverage, 0);
    expect(provider.comparisonPercentage, 0);
  });

  test('erro no repository mantém status error', () async {
    final provider = DashboardProvider(
      repository: FakeAdvancedDashboardRepository(throwOnLoad: true),
      now: () => fixedNow,
    );
    await provider.loadDashboard();
    expect(provider.status, DashboardStatus.error);
    expect(provider.errorMessage, 'Não foi possível carregar o dashboard.');
  });
}
