import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';

void main() {
  test('gasto antigo sem recorrencia continua sendo unico', () {
    final date = DateTime(2026, 8, 5).toIso8601String();
    final expense = Expense.fromMap({
      'id': 1,
      'amount': 20.0,
      'category_id': 'food',
      'description': null,
      'occurred_at': date,
      'created_at': date,
      'updated_at': date,
    });
    expect(expense.recurringPlanId, isNull);
    expect(expense.recurringType, isNull);
    expect(expense.toMap()['recurring_plan_id'], isNull);
  });

  test('plano e parcela preservam metadados no mapeamento', () {
    final date = DateTime(2026, 8, 5);
    final plan = RecurringExpensePlan(
      id: 4,
      type: ExpenseType.installment,
      categoryId: 'food',
      amount: 100,
      startDate: date,
      billingDay: 5,
      totalOccurrences: 3,
      generatedOccurrences: 1,
      createdAt: date,
      updatedAt: date,
    );
    expect(
      RecurringExpensePlan.fromMap(plan.toMap()).type,
      ExpenseType.installment,
    );

    final expense = Expense(
      id: 7,
      amount: 33.34,
      categoryId: 'food',
      occurredAt: date,
      createdAt: date,
      updatedAt: date,
      recurringPlanId: 4,
      occurrenceNumber: 1,
      occurrenceTotal: 3,
      recurringType: ExpenseType.installment,
    );
    final restored = Expense.fromMap(expense.toMap());
    expect(restored.recurringPlanId, 4);
    expect(restored.occurrenceNumber, 1);
    expect(restored.occurrenceTotal, 3);
    expect(restored.recurringType, ExpenseType.installment);
  });
}
