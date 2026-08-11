import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/dashboard_insight.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/core/services/recurring_expense_service.dart';

enum DashboardStatus { initial, loading, ready, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    ExpenseRepository? repository,
    DateTime Function()? now,
    RecurringExpenseService? recurringService,
  }) : _repository = repository ?? ExpenseRepository(),
       _now = now ?? DateTime.now,
       // ignore: prefer_initializing_formals
       _recurringService = recurringService {
    final current = _now();
    _selectedMonth = DateTime(current.year, current.month);
  }

  final ExpenseRepository _repository;
  final DateTime Function() _now;
  final RecurringExpenseService? _recurringService;

  DashboardStatus _status = DashboardStatus.initial;
  double _currentMonthTotal = 0;
  double _previousMonthTotal = 0;
  Map<String, double> _totalsByCategory = const {};
  List<DailyExpenseTotal> _dailyTotals = const [];
  List<MonthlyExpenseSummary> _lastSixMonths = const [];
  double _projectedMonthlyTotal = 0;
  Expense? _highestExpense;
  String? _topCategoryId;
  double _topCategoryTotal = 0;
  double _incomeUsagePercentage = 0;
  double _annualTotal = 0;
  double _annualMonthlyAverage = 0;
  int _annualExpenseCount = 0;
  List<DashboardInsight> _insights = const [];
  double _monthlyIncome = 0;
  Map<String, String> _categoryNames = const {};
  String? _errorMessage;
  late DateTime _selectedMonth;
  Future<void>? _activeLoad;

  DashboardStatus get status => _status;
  double get currentMonthTotal => _currentMonthTotal;
  double get previousMonthTotal => _previousMonthTotal;
  Map<String, double> get totalsByCategory =>
      Map.unmodifiable(_totalsByCategory);
  List<MapEntry<String, double>> get rankedCategoryTotals {
    final entries = _totalsByCategory.entries
        .where((entry) => entry.value > 0)
        .toList();
    entries.sort((first, second) {
      final byValue = second.value.compareTo(first.value);
      return byValue != 0 ? byValue : first.key.compareTo(second.key);
    });
    return List.unmodifiable(entries);
  }

  List<DailyExpenseTotal> get dailyTotals => List.unmodifiable(_dailyTotals);
  List<MonthlyExpenseSummary> get lastSixMonths =>
      List.unmodifiable(_lastSixMonths);
  double get projectedMonthlyTotal => _projectedMonthlyTotal;
  Expense? get highestExpense => _highestExpense;
  String? get topCategoryId => _topCategoryId;
  double get topCategoryTotal => _topCategoryTotal;
  double get incomeUsagePercentage => _incomeUsagePercentage;
  double get annualTotal => _annualTotal;
  double get annualMonthlyAverage => _annualMonthlyAverage;
  int get annualExpenseCount => _annualExpenseCount;
  List<DashboardInsight> get insights => List.unmodifiable(_insights);
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _status == DashboardStatus.loading;

  bool get canGoToNextMonth {
    final now = _now();
    final currentMonth = DateTime(now.year, now.month);
    return _selectedMonth.isBefore(currentMonth);
  }

  double get comparisonPercentage {
    if (_previousMonthTotal == 0) {
      return _currentMonthTotal > 0 ? 100 : 0;
    }
    return ((_currentMonthTotal - _previousMonthTotal) / _previousMonthTotal) *
        100;
  }

  double get dailyAverage {
    if (_currentMonthTotal == 0) return 0;
    final now = _now();
    final currentMonth = DateTime(now.year, now.month);
    final divisor = _selectedMonth == currentMonth
        ? math.max(1, now.day)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return _currentMonthTotal / divisor;
  }

  void setFinancialContext({
    required double monthlyIncome,
    required List<ExpenseCategory> categories,
  }) {
    final names = {
      for (final category in categories) category.id: category.name,
    };
    if (_monthlyIncome == monthlyIncome && mapEquals(_categoryNames, names)) {
      return;
    }
    _monthlyIncome = monthlyIncome;
    _categoryNames = names;
    if (_status == DashboardStatus.ready) {
      _calculateIncomeUsage();
      _insights = _buildInsights();
      notifyListeners();
    }
  }

  Future<void> loadDashboard() {
    final activeLoad = _activeLoad;
    if (activeLoad != null) return activeLoad;
    final load = _performLoad();
    _activeLoad = load;
    load.whenComplete(() => _activeLoad = null);
    return load;
  }

  Future<void> _performLoad() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final selectedStart = DateTime(_selectedMonth.year, _selectedMonth.month);
    final selectedEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final sixMonthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 5,
    );
    final now = _now();
    final annualStart = DateTime(_selectedMonth.year);
    final annualEndMonth = _selectedMonth.year == now.year
        ? DateTime(now.year, now.month)
        : DateTime(_selectedMonth.year, 12);
    final summariesStart = sixMonthStart.isBefore(annualStart)
        ? sixMonthStart
        : annualStart;
    final summariesEnd = _selectedMonth.isAfter(annualEndMonth)
        ? _selectedMonth
        : annualEndMonth;

    try {
      await _recurringService?.generateDueOccurrences(now: now);
      final summariesFuture = _repository.getMonthlySummaries(
        startMonth: summariesStart,
        endMonth: summariesEnd,
      );
      final categoriesFuture = _repository.getTotalsByCategory(
        start: selectedStart,
        end: selectedEnd,
      );
      final dailyFuture = _repository.getDailyTotalsBetween(
        start: selectedStart,
        end: selectedEnd,
      );
      final highestFuture = _repository.getHighestExpenseBetween(
        start: selectedStart,
        end: selectedEnd,
      );

      await Future.wait<Object?>([
        summariesFuture,
        categoriesFuture,
        dailyFuture,
        highestFuture,
      ]);
      final summaries = await summariesFuture;
      _totalsByCategory = await categoriesFuture;
      _dailyTotals = await dailyFuture;
      _highestExpense = await highestFuture;

      _lastSixMonths = _fillLastSixMonths(summaries);
      _currentMonthTotal = _summaryTotalFor(summaries, selectedStart);
      _previousMonthTotal = _summaryTotalFor(
        summaries,
        DateTime(selectedStart.year, selectedStart.month - 1),
      );
      _calculateProjection();
      _calculateTopCategory();
      _calculateIncomeUsage();
      _calculateAnnualSummary(summaries);
      _insights = _buildInsights();
      _status = DashboardStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar o dashboard.';
      _status = DashboardStatus.error;
    }

    notifyListeners();
  }

  Future<void> selectMonth(DateTime month) async {
    final activeLoad = _activeLoad;
    if (activeLoad != null) await activeLoad;
    final normalized = DateTime(month.year, month.month);
    final now = _now();
    final currentMonth = DateTime(now.year, now.month);
    if (normalized.isAfter(currentMonth) || normalized == _selectedMonth) {
      return;
    }
    _selectedMonth = normalized;
    await loadDashboard();
  }

  Future<void> previousMonth() =>
      selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  Future<void> nextMonth() {
    if (!canGoToNextMonth) return Future.value();
    return selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  List<MonthlyExpenseSummary> _fillLastSixMonths(
    List<MonthlyExpenseSummary> summaries,
  ) {
    final byMonth = {
      for (final summary in summaries) _monthKey(summary.month): summary,
    };
    return List.generate(6, (index) {
      final month = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 5 + index,
      );
      return byMonth[_monthKey(month)] ??
          MonthlyExpenseSummary(month: month, total: 0, expenseCount: 0);
    }, growable: false);
  }

  double _summaryTotalFor(
    List<MonthlyExpenseSummary> summaries,
    DateTime month,
  ) {
    final key = _monthKey(month);
    for (final summary in summaries) {
      if (_monthKey(summary.month) == key) return summary.total;
    }
    return 0;
  }

  void _calculateProjection() {
    if (_currentMonthTotal == 0) {
      _projectedMonthlyTotal = 0;
      return;
    }
    final now = _now();
    final currentMonth = DateTime(now.year, now.month);
    if (_selectedMonth != currentMonth) {
      _projectedMonthlyTotal = _currentMonthTotal;
      return;
    }
    final elapsedDays = math.max(1, now.day);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projection = _currentMonthTotal / elapsedDays * daysInMonth;
    _projectedMonthlyTotal = projection.isFinite ? projection : 0;
  }

  void _calculateTopCategory() {
    _topCategoryId = null;
    _topCategoryTotal = 0;
    for (final entry in _totalsByCategory.entries) {
      final isHigher = entry.value > _topCategoryTotal;
      final isDeterministicTie =
          entry.value == _topCategoryTotal &&
          (_topCategoryId == null || entry.key.compareTo(_topCategoryId!) < 0);
      if (isHigher || isDeterministicTie) {
        _topCategoryId = entry.key;
        _topCategoryTotal = entry.value;
      }
    }
    if (_topCategoryTotal <= 0) {
      _topCategoryId = null;
      _topCategoryTotal = 0;
    }
  }

  void _calculateIncomeUsage() {
    if (_monthlyIncome <= 0 || _currentMonthTotal == 0) {
      _incomeUsagePercentage = 0;
      return;
    }
    final percentage = _currentMonthTotal / _monthlyIncome * 100;
    _incomeUsagePercentage = percentage.isFinite ? percentage : 0;
  }

  void _calculateAnnualSummary(List<MonthlyExpenseSummary> summaries) {
    final annual = summaries.where(
      (summary) => summary.month.year == _selectedMonth.year,
    );
    _annualTotal = annual.fold(0, (total, item) => total + item.total);
    _annualExpenseCount = annual.fold(
      0,
      (total, item) => total + item.expenseCount,
    );
    final now = _now();
    final divisor = _selectedMonth.year == now.year
        ? math.max(1, now.month)
        : 12;
    _annualMonthlyAverage = divisor == 0 ? 0 : _annualTotal / divisor;
  }

  List<DashboardInsight> _buildInsights() {
    final insights = <DashboardInsight>[];
    final titles = <String>{};

    void add(DashboardInsight insight) {
      if (insights.length < 3 && titles.add(insight.title)) {
        insights.add(insight);
      }
    }

    if (_monthlyIncome > 0 && _projectedMonthlyTotal > _monthlyIncome) {
      add(
        const DashboardInsight(
          title: 'Projeção acima da renda',
          description:
              'Mantendo o ritmo atual, seus gastos podem ultrapassar sua renda mensal.',
          type: DashboardInsightType.negative,
        ),
      );
    }

    final comparison = comparisonPercentage;
    if (comparison < 0) {
      add(
        DashboardInsight(
          title: 'Boa evolução',
          description:
              'Você gastou ${_formatPercentage(comparison.abs())}% menos que no mês anterior.',
          type: DashboardInsightType.positive,
        ),
      );
    } else if (comparison > 10) {
      add(
        DashboardInsight(
          title: 'Atenção ao aumento',
          description:
              'Seus gastos aumentaram ${_formatPercentage(comparison)}% em relação ao mês anterior.',
          type: DashboardInsightType.warning,
        ),
      );
    }

    if (_currentMonthTotal > 0 && _topCategoryId != null) {
      final percentage = _topCategoryTotal / _currentMonthTotal * 100;
      if (percentage > 40) {
        final categoryName =
            _categoryNames[_topCategoryId] ?? 'A principal categoria';
        add(
          DashboardInsight(
            title: 'Categoria em destaque',
            description:
                '$categoryName representa ${_formatPercentage(percentage)}% dos seus gastos neste mês.',
            type: percentage > 60
                ? DashboardInsightType.warning
                : DashboardInsightType.neutral,
          ),
        );
      }
    }

    return List.unmodifiable(insights);
  }

  int _monthKey(DateTime month) => month.year * 100 + month.month;

  String _formatPercentage(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}
