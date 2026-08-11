import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';
import 'package:quanto_posso/core/services/recurring_expense_service.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';

enum ExpenseStatus { initial, loading, ready, saving, error }

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({
    ExpenseRepository? repository,
    RecurringExpenseRepository? recurringRepository,
    RecurringExpenseService? recurringService,
  }) : _repository = repository ?? ExpenseRepository(),
       // ignore: prefer_initializing_formals
       _recurringRepository = recurringRepository,
       // ignore: prefer_initializing_formals
       _recurringService = recurringService;

  final ExpenseRepository _repository;
  final RecurringExpenseRepository? _recurringRepository;
  final RecurringExpenseService? _recurringService;

  ExpenseStatus _status = ExpenseStatus.initial;
  List<Expense> _recentExpenses = const [];
  double _monthlyTotal = 0;
  String? _errorMessage;

  ExpenseStatus get status => _status;
  List<Expense> get recentExpenses => List.unmodifiable(_recentExpenses);
  double get monthlyTotal => _monthlyTotal;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ExpenseStatus.loading;
  bool get isSaving => _status == ExpenseStatus.saving;

  Future<void> loadCurrentMonth() async {
    _status = ExpenseStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _recurringService?.generateDueOccurrences();
      await _loadData(DateTime.now());
      _status = ExpenseStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar seus gastos.';
      _status = ExpenseStatus.error;
    }

    notifyListeners();
  }

  Future<void> addRecurringExpense({
    required ExpenseType type,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime startDate,
    int? totalOccurrences,
  }) async {
    final repository = _recurringRepository;
    if (repository == null) throw StateError('Recorrência indisponível');
    _status = ExpenseStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.createPlan(
        type: type,
        categoryId: categoryId,
        description: description,
        amount: amount,
        startDate: startDate,
        totalOccurrences: totalOccurrences,
      );
      await _loadData(DateTime.now());
      _status = ExpenseStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível salvar o gasto.';
      _status = ExpenseStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    String? description,
    required DateTime occurredAt,
  }) async {
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'Deve ser maior que zero');
    }

    _status = ExpenseStatus.saving;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();

    try {
      await _repository.createExpense(
        Expense(
          amount: amount,
          categoryId: categoryId,
          description: description,
          occurredAt: occurredAt,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _loadData(now);
      _status = ExpenseStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível salvar o gasto.';
      _status = ExpenseStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense({
    required Expense expense,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime occurredAt,
  }) async {
    if (expense.id == null) {
      throw ArgumentError.value(
        expense.id,
        'expense.id',
        'O id \u00e9 obrigat\u00f3rio',
      );
    }
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'Deve ser maior que zero');
    }

    _status = ExpenseStatus.saving;
    _errorMessage = null;
    notifyListeners();

    final normalizedDescription = description?.trim();
    final now = DateTime.now();
    final updatedExpense = expense.copyWith(
      amount: amount,
      categoryId: categoryId,
      description: normalizedDescription,
      clearDescription:
          normalizedDescription == null || normalizedDescription.isEmpty,
      occurredAt: occurredAt,
      updatedAt: now,
    );

    try {
      await _repository.updateExpense(updatedExpense);
      await _loadData(now);
      _status = ExpenseStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'N\u00e3o foi poss\u00edvel atualizar o gasto.';
      _status = ExpenseStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<RecurringExpensePlan?> getRecurringPlan(int planId) async {
    return _recurringRepository?.getPlanById(planId);
  }

  Future<DateTime?> getNextBillingDate(int planId) async {
    final plan = await getRecurringPlan(planId);
    if (plan == null) return null;
    return RecurringExpenseRepository.planOccurrenceDate(
      plan,
      plan.generatedOccurrences + 1,
    );
  }

  Future<void> updateRecurringExpenseAndFuture({
    required Expense expense,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime nextBillingDate,
  }) async {
    final repository = _recurringRepository;
    if (repository == null) throw StateError('Recorrência indisponível');
    if (expense.recurringPlanId == null || expense.id == null) {
      throw ArgumentError('O lançamento não está vinculado a uma recorrência');
    }
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'Deve ser maior que zero');
    }

    _status = ExpenseStatus.saving;
    _errorMessage = null;
    notifyListeners();
    final now = DateTime.now();
    try {
      await repository.updateExpenseAndFuture(
        expense: expense,
        amount: amount,
        categoryId: categoryId,
        description: description,
        nextBillingDate: nextBillingDate,
        now: now,
      );
      await _loadData(now);
      _status = ExpenseStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível atualizar a recorrência.';
      _status = ExpenseStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadData(DateTime now) async {
    final startOfMonth = DateTime(now.year, now.month);
    final startOfNextMonth = DateTime(now.year, now.month + 1);

    _recentExpenses = await _repository.getRecentExpenses(limit: 5);
    _monthlyTotal = await _repository.getTotalBetween(
      start: startOfMonth,
      end: startOfNextMonth,
    );
  }
}
