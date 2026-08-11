import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

class FakeRecurringEditRepository extends RecurringExpenseRepository {
  FakeRecurringEditRepository(this.plan);

  RecurringExpensePlan plan;
  int updateCalls = 0;
  Expense? updatedExpense;
  double? updatedAmount;
  DateTime? updatedNextBillingDate;

  @override
  Future<RecurringExpensePlan?> getPlanById(int planId) async =>
      plan.id == planId ? plan : null;

  @override
  Future<void> updateExpenseAndFuture({
    required Expense expense,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime nextBillingDate,
    DateTime? now,
  }) async {
    updateCalls++;
    updatedExpense = expense;
    updatedAmount = amount;
    updatedNextBillingDate = nextBillingDate;
  }
}

class FakeEditExpenseRepository extends ExpenseRepository {
  FakeEditExpenseRepository({List<Expense> expenses = const []})
    : expenses = List.of(expenses);

  final List<Expense> expenses;
  Expense? updatedExpense;
  Object? updateError;

  @override
  Future<void> updateExpense(Expense expense) async {
    if (updateError case final error?) throw error;
    updatedExpense = expense;
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index >= 0) expenses[index] = expense;
  }

  @override
  Future<List<Expense>> getRecentExpenses({int limit = 5}) async =>
      expenses.take(limit).toList(growable: false);

  @override
  Future<double> getTotalBetween({
    required DateTime start,
    required DateTime end,
  }) async => expenses
      .where(
        (expense) =>
            !expense.occurredAt.isBefore(start) &&
            expense.occurredAt.isBefore(end),
      )
      .fold<double>(0, (total, expense) => total + expense.amount);

  @override
  Future<List<Expense>> getAllExpenses() async => List.of(expenses);
}

Expense expense({
  int? id = 7,
  double amount = 25,
  String categoryId = 'food',
  String? description = 'Almo\u00e7o',
  DateTime? occurredAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  int? recurringPlanId,
  int? occurrenceNumber,
  int? occurrenceTotal,
  ExpenseType? recurringType,
}) {
  final date = DateTime(2026, 8, 1);
  return Expense(
    id: id,
    amount: amount,
    categoryId: categoryId,
    description: description,
    occurredAt: occurredAt ?? date,
    createdAt: createdAt ?? date,
    updatedAt: updatedAt ?? date,
    recurringPlanId: recurringPlanId,
    occurrenceNumber: occurrenceNumber,
    occurrenceTotal: occurrenceTotal,
    recurringType: recurringType,
  );
}

RecurringExpensePlan recurringPlan() {
  final date = DateTime(2026, 1, 10);
  return RecurringExpensePlan(
    id: 12,
    type: ExpenseType.subscription,
    categoryId: 'food',
    description: 'Plano antigo',
    amount: 29.9,
    startDate: date,
    billingDay: date.day,
    generatedOccurrences: 3,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('update chama repository e preserva id e createdAt', () async {
    final original = expense();
    final repository = FakeEditExpenseRepository(expenses: [original]);
    final provider = ExpenseProvider(repository: repository);
    final newDate = DateTime(2026, 8, 2);

    await provider.updateExpense(
      expense: original,
      amount: 42.5,
      categoryId: 'transport',
      description: '  Uber  ',
      occurredAt: newDate,
    );

    final updated = repository.updatedExpense!;
    expect(updated.id, original.id);
    expect(updated.createdAt, original.createdAt);
    expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
    expect(updated.amount, 42.5);
    expect(updated.categoryId, 'transport');
    expect(updated.description, 'Uber');
    expect(updated.occurredAt, newDate);
    expect(provider.status, ExpenseStatus.ready);
  });

  test('descri\u00e7\u00e3o vazia vira null', () async {
    final original = expense();
    final repository = FakeEditExpenseRepository(expenses: [original]);
    await ExpenseProvider(repository: repository).updateExpense(
      expense: original,
      amount: 25,
      categoryId: 'food',
      description: '   ',
      occurredAt: original.occurredAt,
    );
    expect(repository.updatedExpense?.description, isNull);
  });

  test('gasto sem id lan\u00e7a ArgumentError', () {
    final provider = ExpenseProvider(repository: FakeEditExpenseRepository());
    expect(
      provider.updateExpense(
        expense: expense(id: null),
        amount: 25,
        categoryId: 'food',
        occurredAt: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });

  test('valor zero ou negativo lan\u00e7a ArgumentError', () async {
    final original = expense();
    final provider = ExpenseProvider(repository: FakeEditExpenseRepository());
    for (final amount in [0.0, -1.0]) {
      await expectLater(
        provider.updateExpense(
          expense: original,
          amount: amount,
          categoryId: 'food',
          occurredAt: original.occurredAt,
        ),
        throwsArgumentError,
      );
    }
  });

  test('erro no repository define status error', () async {
    final original = expense();
    final repository = FakeEditExpenseRepository()
      ..updateError = StateError('failure');
    final provider = ExpenseProvider(repository: repository);
    await expectLater(
      provider.updateExpense(
        expense: original,
        amount: 30,
        categoryId: 'food',
        occurredAt: original.occurredAt,
      ),
      throwsStateError,
    );
    expect(provider.status, ExpenseStatus.error);
    expect(
      provider.errorMessage,
      'N\u00e3o foi poss\u00edvel atualizar o gasto.',
    );
  });

  test(
    'HistoryProvider substitui gasto e preserva ordena\u00e7\u00e3o',
    () async {
      final first = expense(id: 1, occurredAt: DateTime(2026, 8, 1));
      final second = expense(id: 2, occurredAt: DateTime(2026, 8, 2));
      final provider = HistoryProvider(
        repository: FakeEditExpenseRepository(expenses: [second, first]),
      );
      await provider.loadHistory();
      final updated = first.copyWith(occurredAt: DateTime(2026, 8, 3));
      await provider.replaceExpense(updated);
      expect(provider.expenses.map((item) => item.id), [1, 2]);
    },
  );

  test('gasto editado deixa de corresponder ao filtro atual', () async {
    final original = expense(description: 'Mercado', categoryId: 'food');
    final provider = HistoryProvider(
      repository: FakeEditExpenseRepository(expenses: [original]),
    );
    await provider.loadHistory();
    provider.setCategoryFilter('food');
    provider.setSearchQuery('mercado');
    expect(provider.filteredExpenses, hasLength(1));
    await provider.replaceExpense(
      original.copyWith(categoryId: 'transport', description: 'Uber'),
    );
    expect(provider.selectedCategoryId, 'food');
    expect(provider.searchQuery, 'mercado');
    expect(provider.filteredExpenses, isEmpty);
  });

  test('edição individual não modifica o plano recorrente', () async {
    final original = expense(
      recurringPlanId: 12,
      occurrenceNumber: 2,
      recurringType: ExpenseType.subscription,
    );
    final expenseRepository = FakeEditExpenseRepository(expenses: [original]);
    final recurringRepository = FakeRecurringEditRepository(recurringPlan());
    final provider = ExpenseProvider(
      repository: expenseRepository,
      recurringRepository: recurringRepository,
    );

    await provider.updateExpense(
      expense: original,
      amount: 35,
      categoryId: 'services',
      occurredAt: original.occurredAt,
    );

    expect(expenseRepository.updatedExpense?.recurringPlanId, 12);
    expect(recurringRepository.updateCalls, 0);
  });

  test(
    'edição futura preserva vínculo e executa uma única atualização',
    () async {
      final original = expense(
        recurringPlanId: 12,
        occurrenceNumber: 3,
        recurringType: ExpenseType.subscription,
      );
      final expenseRepository = FakeEditExpenseRepository(expenses: [original]);
      final recurringRepository = FakeRecurringEditRepository(recurringPlan());
      final provider = ExpenseProvider(
        repository: expenseRepository,
        recurringRepository: recurringRepository,
      );
      final nextBillingDate = DateTime(2026, 4, 15);

      await provider.updateRecurringExpenseAndFuture(
        expense: original,
        amount: 39.9,
        categoryId: 'services',
        description: 'Plano novo',
        nextBillingDate: nextBillingDate,
      );

      expect(recurringRepository.updateCalls, 1);
      expect(recurringRepository.updatedExpense, same(original));
      expect(recurringRepository.updatedExpense?.recurringPlanId, 12);
      expect(recurringRepository.updatedNextBillingDate, nextBillingDate);
      expect(expenseRepository.expenses, hasLength(1));
    },
  );
}
