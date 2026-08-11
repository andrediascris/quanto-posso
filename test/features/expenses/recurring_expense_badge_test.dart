import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/app/theme/app_theme.dart';
import 'package:quanto_posso/features/expenses/widgets/recurring_expense_badge.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';

void main() {
  Expense expense(ExpenseType? type) {
    final now = DateTime(2026, 8, 5);
    return Expense(
      amount: 20,
      categoryId: 'food',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
      recurringPlanId: type == null ? null : 1,
      occurrenceNumber: type == ExpenseType.installment ? 2 : 1,
      occurrenceTotal: type == ExpenseType.installment ? 6 : null,
      recurringType: type,
    );
  }

  testWidgets('identifica assinatura e parcela', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              RecurringExpenseBadge(expense: expense(ExpenseType.subscription)),
              RecurringExpenseBadge(expense: expense(ExpenseType.installment)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Assinatura'), findsOneWidget);
    expect(find.text('Parcela 2 de 6'), findsOneWidget);
  });

  testWidgets('nao mostra badge para gasto unico', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RecurringExpenseBadge(expense: expense(null)),
      ),
    );
    expect(find.byType(Container), findsNothing);
  });
}
