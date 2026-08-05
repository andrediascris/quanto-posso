import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';

class FakeHistoryExpenseRepository extends ExpenseRepository {
  FakeHistoryExpenseRepository({
    List<Expense> expenses = const [],
    this.throwOnLoad = false,
  }) : _expenses = List.of(expenses);

  final List<Expense> _expenses;
  final bool throwOnLoad;
  int? deletedId;

  @override
  Future<List<Expense>> getAllExpenses() async {
    if (throwOnLoad) {
      throw StateError('Falha simulada');
    }
    return List.unmodifiable(_expenses);
  }

  @override
  Future<void> deleteExpense(int id) async {
    deletedId = id;
    _expenses.removeWhere((expense) => expense.id == id);
  }
}

void main() {
  final now = DateTime(2026, 8, 4);
  final expenses = [
    Expense(
      id: 1,
      amount: 25,
      categoryId: 'food',
      description: 'Almoço no trabalho',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 2,
      amount: 80,
      categoryId: 'market',
      description: 'Compras do mês',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 3,
      amount: 15,
      categoryId: 'food',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  test('loadHistory carrega despesas e finaliza pronto', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: expenses),
    );

    await provider.loadHistory();

    expect(provider.status, HistoryStatus.ready);
    expect(provider.expenses, expenses);
  });

  test('pesquisa por descrição ignora maiúsculas e minúsculas', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: expenses),
    );
    await provider.loadHistory();

    provider.setSearchQuery('ALMOÇO');

    expect(provider.filteredExpenses.map((expense) => expense.id), [1]);
  });

  test('filtro por categoria retorna apenas a categoria escolhida', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: expenses),
    );
    await provider.loadHistory();

    provider.setCategoryFilter('food');

    expect(provider.filteredExpenses.map((expense) => expense.id), [1, 3]);
  });

  test('combina pesquisa e filtro de categoria', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: expenses),
    );
    await provider.loadHistory();

    provider
      ..setSearchQuery('compras')
      ..setCategoryFilter('market');

    expect(provider.filteredExpenses.map((expense) => expense.id), [2]);
  });

  test('deleteExpense remove localmente e envia o id ao repository', () async {
    final repository = FakeHistoryExpenseRepository(expenses: expenses);
    final provider = HistoryProvider(repository: repository);
    await provider.loadHistory();

    await provider.deleteExpense(1);

    expect(repository.deletedId, 1);
    expect(provider.expenses.any((expense) => expense.id == 1), isFalse);
    expect(provider.status, HistoryStatus.ready);
  });

  test('erro ao carregar define status e mensagem', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(throwOnLoad: true),
    );

    await provider.loadHistory();

    expect(provider.status, HistoryStatus.error);
    expect(provider.errorMessage, 'Não foi possível carregar o histórico.');
  });
}
