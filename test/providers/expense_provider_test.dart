import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

class FakeExpenseRepository extends ExpenseRepository {
  FakeExpenseRepository({
    List<Expense> expenses = const [],
    this.throwOnLoad = false,
  }) : _expenses = List.of(expenses);

  final List<Expense> _expenses;
  final bool throwOnLoad;
  Expense? receivedExpense;

  @override
  Future<Expense> createExpense(Expense expense) async {
    receivedExpense = expense;
    final savedExpense = expense.copyWith(id: _expenses.length + 1);
    _expenses.add(savedExpense);
    return savedExpense;
  }

  @override
  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    if (throwOnLoad) {
      throw StateError('Falha simulada');
    }

    final sorted = List<Expense>.of(_expenses)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return sorted.take(limit).toList(growable: false);
  }

  @override
  Future<double> getTotalBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (throwOnLoad) {
      throw StateError('Falha simulada');
    }

    return _expenses
        .where(
          (expense) =>
              !expense.occurredAt.isBefore(start) &&
              expense.occurredAt.isBefore(end),
        )
        .fold<double>(0.0, (total, expense) => total + expense.amount);
  }
}

void main() {
  Expense currentMonthExpense({double amount = 25.0}) {
    final now = DateTime.now();
    return Expense(
      id: 1,
      amount: amount,
      categoryId: 'food',
      description: 'Almoço',
      occurredAt: DateTime(now.year, now.month, 2),
      createdAt: now,
      updatedAt: now,
    );
  }

  test('loadCurrentMonth carrega recentes e total mensal', () async {
    final expense = currentMonthExpense();
    final provider = ExpenseProvider(
      repository: FakeExpenseRepository(expenses: [expense]),
    );

    expect(provider.status, ExpenseStatus.initial);

    await provider.loadCurrentMonth();

    expect(provider.status, ExpenseStatus.ready);
    expect(provider.monthlyTotal, expense.amount);
    expect(provider.recentExpenses, [expense]);
  });

  test('addExpense salva os dados e atualiza o total', () async {
    final repository = FakeExpenseRepository();
    final provider = ExpenseProvider(repository: repository);
    final now = DateTime.now();

    await provider.addExpense(
      amount: 42.5,
      categoryId: 'market',
      description: 'Compras',
      occurredAt: now,
    );

    expect(repository.receivedExpense?.amount, 42.5);
    expect(repository.receivedExpense?.categoryId, 'market');
    expect(repository.receivedExpense?.description, 'Compras');
    expect(provider.monthlyTotal, 42.5);
    expect(provider.status, ExpenseStatus.ready);
  });

  test(
    'define status e mensagem de erro quando o carregamento falha',
    () async {
      final provider = ExpenseProvider(
        repository: FakeExpenseRepository(throwOnLoad: true),
      );

      await provider.loadCurrentMonth();

      expect(provider.status, ExpenseStatus.error);
      expect(provider.errorMessage, 'Não foi possível carregar seus gastos.');
    },
  );
}
