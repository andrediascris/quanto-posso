import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/core/services/recurring_expense_service.dart';

enum HistoryStatus { initial, loading, ready, deleting, error }

enum HistoryPeriod { all, today, lastSevenDays, thisMonth, lastMonth, custom }

enum HistorySort {
  newest,
  oldest,
  highestValue,
  lowestValue,
  categoryAscending,
  categoryDescending,
}

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({
    ExpenseRepository? repository,
    DateTime Function()? now,
    RecurringExpenseService? recurringService,
  }) : _repository = repository ?? ExpenseRepository(),
       _now = now ?? DateTime.now,
       // ignore: prefer_initializing_formals
       _recurringService = recurringService;

  final ExpenseRepository _repository;
  final DateTime Function() _now;
  final RecurringExpenseService? _recurringService;

  HistoryStatus _status = HistoryStatus.initial;
  List<Expense> _expenses = const [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  HistoryPeriod _selectedPeriod = HistoryPeriod.all;
  DateTime? _customPeriodStart;
  DateTime? _customPeriodEnd;
  double? _minimumValue;
  double? _maximumValue;
  HistorySort _sort = HistorySort.newest;
  Map<String, String> _categoryNames = const {};
  String? _errorMessage;

  HistoryStatus get status => _status;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  HistoryPeriod get selectedPeriod => _selectedPeriod;
  DateTime? get customPeriodStart => _customPeriodStart;
  DateTime? get customPeriodEnd => _customPeriodEnd;
  double? get minimumValue => _minimumValue;
  double? get maximumValue => _maximumValue;
  HistorySort get sort => _sort;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HistoryStatus.loading;
  bool get isDeleting => _status == HistoryStatus.deleting;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedPeriod != HistoryPeriod.all ||
      _minimumValue != null ||
      _maximumValue != null ||
      _sort != HistorySort.newest;

  int get activeFilterCount {
    var count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedCategoryId != null) count++;
    if (_selectedPeriod != HistoryPeriod.all) count++;
    if (_minimumValue != null || _maximumValue != null) count++;
    if (_sort != HistorySort.newest) count++;
    return count;
  }

  List<Expense> get filteredExpenses {
    final normalizedQuery = _searchQuery.toLowerCase();
    final period = _periodBounds();
    final result = _expenses.where((expense) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          (expense.description?.toLowerCase().contains(normalizedQuery) ??
              false);
      final matchesCategory =
          _selectedCategoryId == null ||
          expense.categoryId == _selectedCategoryId;
      final matchesMinimum =
          _minimumValue == null || expense.amount >= _minimumValue!;
      final matchesMaximum =
          _maximumValue == null || expense.amount <= _maximumValue!;
      final matchesPeriod =
          period == null ||
          (!expense.occurredAt.isBefore(period.$1) &&
              expense.occurredAt.isBefore(period.$2));
      return matchesSearch &&
          matchesCategory &&
          matchesMinimum &&
          matchesMaximum &&
          matchesPeriod;
    }).toList();

    result.sort(_compareExpenses);
    return List.unmodifiable(result);
  }

  double get filteredTotal =>
      filteredExpenses.fold(0, (total, expense) => total + expense.amount);

  Future<void> loadHistory() async {
    _status = HistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _recurringService?.generateDueOccurrences(now: _now());
      _expenses = await _repository.getAllExpenses();
      _status = HistoryStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar o histórico.';
      _status = HistoryStatus.error;
    }

    notifyListeners();
  }

  void setCategories(List<ExpenseCategory> categories) {
    final names = {
      for (final category in categories) category.id: category.name,
    };
    if (mapEquals(_categoryNames, names)) return;
    _categoryNames = names;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    final query = value.trim();
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setPeriod(HistoryPeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    if (period != HistoryPeriod.custom) {
      _customPeriodStart = null;
      _customPeriodEnd = null;
    }
    notifyListeners();
  }

  void setCustomPeriod({required DateTime start, required DateTime end}) {
    final normalizedStart = _startOfDay(start);
    final normalizedEnd = _startOfDay(end);
    _selectedPeriod = HistoryPeriod.custom;
    _customPeriodStart = normalizedStart;
    _customPeriodEnd = normalizedEnd;
    notifyListeners();
  }

  void setValueRange({double? minimum, double? maximum}) {
    if (_minimumValue == minimum && _maximumValue == maximum) return;
    _minimumValue = minimum;
    _maximumValue = maximum;
    notifyListeners();
  }

  void setSort(HistorySort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedPeriod = HistoryPeriod.all;
    _customPeriodStart = null;
    _customPeriodEnd = null;
    _minimumValue = null;
    _maximumValue = null;
    _sort = HistorySort.newest;
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    _status = HistoryStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteExpense(id);
      _expenses = _expenses.where((expense) => expense.id != id).toList();
      _status = HistoryStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível excluir o gasto.';
      _status = HistoryStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> replaceExpense(Expense updatedExpense) async {
    final id = updatedExpense.id;
    if (id == null) {
      throw ArgumentError.value(id, 'updatedExpense.id', 'O id é obrigatório');
    }
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index < 0) {
      throw StateError('Gasto não encontrado no histórico.');
    }
    final updated = List<Expense>.of(_expenses)..[index] = updatedExpense;
    updated.sort((first, second) {
      final dateComparison = second.occurredAt.compareTo(first.occurredAt);
      if (dateComparison != 0) return dateComparison;
      return (second.id ?? -1).compareTo(first.id ?? -1);
    });
    _expenses = updated;
    notifyListeners();
  }

  (DateTime, DateTime)? _periodBounds() {
    final today = _startOfDay(_now());
    return switch (_selectedPeriod) {
      HistoryPeriod.all => null,
      HistoryPeriod.today => (today, today.add(const Duration(days: 1))),
      HistoryPeriod.lastSevenDays => (
        today.subtract(const Duration(days: 6)),
        today.add(const Duration(days: 1)),
      ),
      HistoryPeriod.thisMonth => (
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1),
      ),
      HistoryPeriod.lastMonth => (
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month),
      ),
      HistoryPeriod.custom =>
        _customPeriodStart == null || _customPeriodEnd == null
            ? null
            : (
                _customPeriodStart!,
                _customPeriodEnd!.add(const Duration(days: 1)),
              ),
    };
  }

  int _compareExpenses(Expense first, Expense second) {
    final comparison = switch (_sort) {
      HistorySort.newest => second.occurredAt.compareTo(first.occurredAt),
      HistorySort.oldest => first.occurredAt.compareTo(second.occurredAt),
      HistorySort.highestValue => second.amount.compareTo(first.amount),
      HistorySort.lowestValue => first.amount.compareTo(second.amount),
      HistorySort.categoryAscending => _categoryName(
        first,
      ).compareTo(_categoryName(second)),
      HistorySort.categoryDescending => _categoryName(
        second,
      ).compareTo(_categoryName(first)),
    };
    return comparison;
  }

  String _categoryName(Expense expense) =>
      (_categoryNames[expense.categoryId] ?? expense.categoryId).toLowerCase();

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
