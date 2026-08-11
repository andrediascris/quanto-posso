import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

class FakeRecurringRepository extends RecurringExpenseRepository {
  FakeRecurringRepository(this.storedPlans, {this.expenses = const []});
  List<RecurringExpensePlan> storedPlans;
  final List<Expense> expenses;
  int? cancelledId;

  @override
  Future<List<RecurringExpensePlan>> getPlans() async =>
      List.unmodifiable(storedPlans);

  @override
  Future<List<Expense>> getExpensesForPlan(int planId) async => expenses
      .where((expense) => expense.recurringPlanId == planId)
      .toList(growable: false);

  @override
  Future<void> cancelPlan(int planId, {DateTime? now}) async {
    cancelledId = planId;
    storedPlans = [
      for (final plan in storedPlans)
        if (plan.id == planId)
          RecurringExpensePlan.fromMap({
            ...plan.toMap(),
            'is_active': 0,
            'status': 'cancelled',
          })
        else
          plan,
    ];
  }
}

void main() {
  final now = DateTime(2026, 8, 10);
  RecurringExpensePlan plan({
    required int id,
    required ExpenseType type,
    required double amount,
    int? total,
    int generated = 0,
    RecurringPlanStatus status = RecurringPlanStatus.active,
  }) => RecurringExpensePlan(
    id: id,
    type: type,
    categoryId: 'food',
    amount: amount,
    startDate: now,
    billingDay: 10,
    totalOccurrences: total,
    generatedOccurrences: generated,
    isActive: status == RecurringPlanStatus.active,
    status: status,
    createdAt: now,
    updatedAt: now,
  );

  test('carrega, filtra e resume apenas planos ativos', () async {
    final repository = FakeRecurringRepository([
      plan(id: 1, type: ExpenseType.subscription, amount: 49.9),
      plan(id: 2, type: ExpenseType.installment, amount: 100, total: 3),
      plan(
        id: 3,
        type: ExpenseType.subscription,
        amount: 20,
        total: 2,
        generated: 2,
        status: RecurringPlanStatus.completed,
      ),
    ]);
    final provider = RecurringExpenseProvider(repository: repository);
    await provider.loadPlans();
    expect(provider.activePlans, hasLength(2));
    expect(provider.completedPlans, hasLength(1));
    expect(provider.activeSubscriptionCount, 1);
    expect(provider.activeInstallmentCount, 1);
    expect(provider.totalMonthlyCommitment, closeTo(83.24, 0.001));

    provider.setFilter(RecurringPlanFilter.subscriptions);
    expect(provider.filteredPlans.map((item) => item.id), [1, 3]);
    provider.setFilter(RecurringPlanFilter.completed);
    expect(provider.filteredPlans.single.id, 3);
  });

  test('cancelamento é não físico e preserva lançamentos', () async {
    final active = plan(id: 1, type: ExpenseType.subscription, amount: 49.9);
    final expense = Expense(
      id: 9,
      amount: 49.9,
      categoryId: 'food',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
      recurringPlanId: 1,
      occurrenceNumber: 1,
      recurringType: ExpenseType.subscription,
    );
    final repository = FakeRecurringRepository([active], expenses: [expense]);
    final provider = RecurringExpenseProvider(repository: repository);
    await provider.loadPlans();
    await provider.cancelPlan(1);
    expect(repository.cancelledId, 1);
    expect(provider.plans, hasLength(1));
    expect(provider.plans.single.status, RecurringPlanStatus.cancelled);
    expect(provider.activePlans, isEmpty);
    expect(await provider.getPlanExpenses(1), [expense]);
  });

  test('próxima cobrança reutiliza calendário e não altera o plano', () {
    final monthly = RecurringExpensePlan(
      id: 1,
      type: ExpenseType.subscription,
      categoryId: 'food',
      amount: 20,
      startDate: DateTime(2026, 1, 31),
      billingDay: 31,
      generatedOccurrences: 1,
      createdAt: now,
      updatedAt: now,
    );
    expect(
      RecurringExpenseProvider.nextOccurrence(monthly),
      DateTime(2026, 2, 28),
    );
    expect(monthly.generatedOccurrences, 1);
  });

  test('mapa antigo infere status sem alterar compatibilidade', () {
    Map<String, Object?> oldMap({
      required int active,
      int? total,
      int generated = 0,
    }) => {
      'id': 1,
      'type': 'subscription',
      'category_id': 'food',
      'description': null,
      'amount': 20.0,
      'start_date': now.toIso8601String(),
      'billing_day': 10,
      'total_occurrences': total,
      'generated_occurrences': generated,
      'is_active': active,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    expect(
      RecurringExpensePlan.fromMap(oldMap(active: 1)).status,
      RecurringPlanStatus.active,
    );
    expect(
      RecurringExpensePlan.fromMap(
        oldMap(active: 0, total: 2, generated: 2),
      ).status,
      RecurringPlanStatus.completed,
    );
    expect(
      RecurringExpensePlan.fromMap(oldMap(active: 0)).status,
      RecurringPlanStatus.cancelled,
    );
  });
}
