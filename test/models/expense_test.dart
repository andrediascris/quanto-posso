import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 8, 4, 12, 30);
  final createdAt = DateTime.utc(2026, 8, 4, 13);
  final updatedAt = DateTime.utc(2026, 8, 4, 14);

  Expense createExpense({String? description = 'Almoço'}) {
    return Expense(
      amount: 35.5,
      categoryId: 'food',
      description: description,
      occurredAt: occurredAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  test('toMap converte os campos e omite id nulo', () {
    final map = createExpense().toMap();

    expect(map.containsKey('id'), isFalse);
    expect(map['amount'], 35.5);
    expect(map['category_id'], 'food');
    expect(map['description'], 'Almoço');
    expect(map['occurred_at'], occurredAt.toIso8601String());
    expect(map['created_at'], createdAt.toIso8601String());
    expect(map['updated_at'], updatedAt.toIso8601String());
  });

  test('fromMap recupera todos os campos e converte amount para double', () {
    final map = <String, Object?>{
      'id': 7,
      'amount': 35,
      'category_id': 'food',
      'description': 'Almoço',
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    final expense = Expense.fromMap(map);

    expect(expense.id, 7);
    expect(expense.amount, 35.0);
    expect(expense.amount, isA<double>());
    expect(expense.categoryId, 'food');
    expect(expense.description, 'Almoço');
    expect(expense.occurredAt, occurredAt);
    expect(expense.createdAt, createdAt);
    expect(expense.updatedAt, updatedAt);
  });

  test('copyWith mantém valores não informados', () {
    final expense = createExpense();
    final copy = expense.copyWith(amount: 42.0);

    expect(copy.id, expense.id);
    expect(copy.amount, 42.0);
    expect(copy.categoryId, expense.categoryId);
    expect(copy.description, expense.description);
    expect(copy.occurredAt, expense.occurredAt);
    expect(copy.createdAt, expense.createdAt);
    expect(copy.updatedAt, expense.updatedAt);
  });

  test('copyWith remove a descrição quando clearDescription é true', () {
    final expense = createExpense();
    final copy = expense.copyWith(clearDescription: true);

    expect(copy.description, isNull);
  });
}
