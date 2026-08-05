import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

enum HistoryStatus { initial, loading, ready, deleting, error }

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({ExpenseRepository? repository})
    : _repository = repository ?? ExpenseRepository();

  final ExpenseRepository _repository;

  HistoryStatus _status = HistoryStatus.initial;
  List<Expense> _expenses = const [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _errorMessage;

  HistoryStatus get status => _status;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HistoryStatus.loading;
  bool get isDeleting => _status == HistoryStatus.deleting;

  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty && _selectedCategoryId == null) {
      return List.unmodifiable(_expenses);
    }

    final normalizedQuery = _searchQuery.toLowerCase();
    return List.unmodifiable(
      _expenses.where((expense) {
        final matchesSearch =
            normalizedQuery.isEmpty ||
            (expense.description?.toLowerCase().contains(normalizedQuery) ??
                false);
        final matchesCategory =
            _selectedCategoryId == null ||
            expense.categoryId == _selectedCategoryId;
        return matchesSearch && matchesCategory;
      }),
    );
  }

  Future<void> loadHistory() async {
    _status = HistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.getAllExpenses();
      _status = HistoryStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar o histórico.';
      _status = HistoryStatus.error;
    }

    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    if (_searchQuery.isEmpty && _selectedCategoryId == null) {
      return;
    }

    _searchQuery = '';
    _selectedCategoryId = null;
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
      throw ArgumentError.value(
        id,
        'updatedExpense.id',
        'O id \u00e9 obrigat\u00f3rio',
      );
    }
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index < 0) {
      throw StateError('Gasto n\u00e3o encontrado no hist\u00f3rico.');
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
}
