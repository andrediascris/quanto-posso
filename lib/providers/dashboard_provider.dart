import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

enum DashboardStatus { initial, loading, ready, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({ExpenseRepository? repository})
    : _repository = repository ?? ExpenseRepository();

  final ExpenseRepository _repository;

  DashboardStatus _status = DashboardStatus.initial;
  double _currentMonthTotal = 0;
  double _previousMonthTotal = 0;
  Map<String, double> _totalsByCategory = const {};
  List<DailyExpenseTotal> _dailyTotals = const [];
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DashboardStatus get status => _status;
  double get currentMonthTotal => _currentMonthTotal;
  double get previousMonthTotal => _previousMonthTotal;
  Map<String, double> get totalsByCategory =>
      Map.unmodifiable(_totalsByCategory);
  List<DailyExpenseTotal> get dailyTotals => List.unmodifiable(_dailyTotals);
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _status == DashboardStatus.loading;

  bool get canGoToNextMonth {
    final now = DateTime.now();
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
    if (_currentMonthTotal == 0) {
      return 0;
    }
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final divisor = _selectedMonth == currentMonth
        ? now.day
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return divisor == 0 ? 0 : _currentMonthTotal / divisor;
  }

  Future<void> loadDashboard() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final previous = DateTime(_selectedMonth.year, _selectedMonth.month - 1);

    try {
      final currentFuture = _repository.getTotalBetween(
        start: start,
        end: next,
      );
      final previousFuture = _repository.getTotalBetween(
        start: previous,
        end: start,
      );
      final categoriesFuture = _repository.getTotalsByCategory(
        start: start,
        end: next,
      );
      final dailyFuture = _repository.getDailyTotalsBetween(
        start: start,
        end: next,
      );

      await Future.wait<Object>([
        currentFuture,
        previousFuture,
        categoriesFuture,
        dailyFuture,
      ]);
      _currentMonthTotal = await currentFuture;
      _previousMonthTotal = await previousFuture;
      _totalsByCategory = await categoriesFuture;
      _dailyTotals = await dailyFuture;
      _status = DashboardStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar o dashboard.';
      _status = DashboardStatus.error;
    }

    notifyListeners();
  }

  Future<void> selectMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (normalized.isAfter(currentMonth) || normalized == _selectedMonth) {
      return;
    }
    _selectedMonth = normalized;
    await loadDashboard();
  }

  Future<void> previousMonth() {
    return selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  }

  Future<void> nextMonth() {
    if (!canGoToNextMonth) {
      return Future.value();
    }
    return selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }
}
