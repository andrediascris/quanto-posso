import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

enum RecurringExpenseStatus { initial, loading, ready, error }

enum RecurringPlanFilter { all, subscriptions, installments, completed }

class RecurringExpenseProvider extends ChangeNotifier {
  RecurringExpenseProvider({RecurringExpenseRepository? repository})
    // ignore: prefer_initializing_formals
    : _repository = repository;

  final RecurringExpenseRepository? _repository;
  RecurringExpenseStatus _status = RecurringExpenseStatus.initial;
  RecurringPlanFilter _filter = RecurringPlanFilter.all;
  List<RecurringExpensePlan> _plans = const [];
  String? _errorMessage;

  RecurringExpenseStatus get status => _status;
  RecurringPlanFilter get filter => _filter;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RecurringExpenseStatus.loading;
  List<RecurringExpensePlan> get plans => List.unmodifiable(_plans);
  List<RecurringExpensePlan> get activePlans => List.unmodifiable(
    _plans.where((plan) => plan.status == RecurringPlanStatus.active),
  );
  List<RecurringExpensePlan> get completedPlans => List.unmodifiable(
    _plans.where((plan) => plan.status != RecurringPlanStatus.active),
  );

  List<RecurringExpensePlan> get filteredPlans => List.unmodifiable(
    _plans.where(
      (plan) => switch (_filter) {
        RecurringPlanFilter.all => true,
        RecurringPlanFilter.subscriptions =>
          plan.type == ExpenseType.subscription,
        RecurringPlanFilter.installments =>
          plan.type == ExpenseType.installment,
        RecurringPlanFilter.completed =>
          plan.status != RecurringPlanStatus.active,
      },
    ),
  );

  int get activeSubscriptionCount =>
      activePlans.where((plan) => plan.type == ExpenseType.subscription).length;
  int get activeInstallmentCount =>
      activePlans.where((plan) => plan.type == ExpenseType.installment).length;
  double get totalMonthlyCommitment => activePlans.fold(0.0, (total, plan) {
    final amount = plan.type == ExpenseType.subscription
        ? plan.amount
        : RecurringExpenseRepository.occurrenceAmount(
            plan,
            plan.generatedOccurrences + 1,
          );
    return total + amount;
  });

  Future<void> loadPlans() async {
    _status = RecurringExpenseStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _plans = await _repository?.getPlans() ?? const [];
      _status = RecurringExpenseStatus.ready;
    } on Object {
      _status = RecurringExpenseStatus.error;
      _errorMessage = 'Não foi possível carregar suas recorrências.';
    }
    notifyListeners();
  }

  Future<void> reload() => loadPlans();

  void setFilter(RecurringPlanFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> cancelPlan(int planId) async {
    final repository = _repository;
    if (repository == null) throw StateError('Recorrência indisponível');
    _errorMessage = null;
    try {
      await repository.cancelPlan(planId);
      _plans = await repository.getPlans();
      _status = RecurringExpenseStatus.ready;
      notifyListeners();
    } on Object {
      _status = RecurringExpenseStatus.error;
      _errorMessage = 'Não foi possível encerrar esta recorrência.';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Expense>> getPlanExpenses(int planId) async =>
      _repository?.getExpensesForPlan(planId) ?? const [];

  static DateTime? nextOccurrence(RecurringExpensePlan plan) {
    if (plan.status != RecurringPlanStatus.active) return null;
    final nextNumber = plan.generatedOccurrences + 1;
    if (plan.totalOccurrences != null && nextNumber > plan.totalOccurrences!) {
      return null;
    }
    return RecurringExpenseRepository.occurrenceDate(
      plan.startDate,
      nextNumber,
    );
  }
}
