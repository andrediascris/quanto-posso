import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
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
  int loadCount = 0;

  @override
  Future<List<Expense>> getAllExpenses() async {
    loadCount++;
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

  final advancedExpenses = [
    Expense(
      id: 10,
      amount: 60,
      categoryId: 'food',
      description: 'Assinatura básica',
      occurredAt: DateTime(2026, 8, 5, 9),
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 11,
      amount: 100,
      categoryId: 'food',
      description: 'Assinatura premium',
      occurredAt: DateTime(2026, 8, 2, 18),
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 12,
      amount: 80,
      categoryId: 'food',
      description: 'Assinatura antiga',
      occurredAt: DateTime(2026, 7, 31, 12),
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 13,
      amount: 90,
      categoryId: 'market',
      description: 'Assinatura mercado',
      occurredAt: DateTime(2026, 8, 1, 8),
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 14,
      amount: 25,
      categoryId: 'transport',
      description: 'Táxi',
      occurredAt: DateTime(2026, 7, 10),
      createdAt: now,
      updatedAt: now,
    ),
    Expense(
      id: 15,
      amount: 40,
      categoryId: 'market',
      description: 'Compras antigas',
      occurredAt: DateTime(2026, 6, 30),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final categories = [
    ExpenseCategory(
      id: 'food',
      name: 'Alimentação',
      iconCodePoint: 0,
      iconFontFamily: 'MaterialIcons',
      colorValue: 0,
      isDefault: true,
      createdAt: now,
    ),
    ExpenseCategory(
      id: 'market',
      name: 'Mercado',
      iconCodePoint: 0,
      iconFontFamily: 'MaterialIcons',
      colorValue: 0,
      isDefault: true,
      createdAt: now,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transporte',
      iconCodePoint: 0,
      iconFontFamily: 'MaterialIcons',
      colorValue: 0,
      isDefault: true,
      createdAt: now,
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

  test('combina período, categoria, valores, pesquisa e ordenação', () async {
    final repository = FakeHistoryExpenseRepository(expenses: advancedExpenses);
    final provider = HistoryProvider(
      repository: repository,
      now: () => DateTime(2026, 8, 5, 20),
    );
    await provider.loadHistory();

    provider
      ..setSearchQuery('ASSINATURA')
      ..setCategoryFilter('food')
      ..setPeriod(HistoryPeriod.lastSevenDays)
      ..setValueRange(minimum: 70, maximum: 110)
      ..setSort(HistorySort.highestValue);

    expect(provider.filteredExpenses.map((expense) => expense.id), [11, 12]);
    expect(provider.filteredTotal, 180);
    expect(provider.activeFilterCount, 5);
    expect(repository.loadCount, 1);
  });

  test('aplica corretamente todos os períodos predefinidos', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: advancedExpenses),
      now: () => DateTime(2026, 8, 5, 20),
    );
    await provider.loadHistory();

    provider.setPeriod(HistoryPeriod.today);
    expect(provider.filteredExpenses.map((expense) => expense.id), [10]);

    provider.setPeriod(HistoryPeriod.lastSevenDays);
    expect(provider.filteredExpenses.map((expense) => expense.id), [
      10,
      11,
      13,
      12,
    ]);

    provider.setPeriod(HistoryPeriod.thisMonth);
    expect(provider.filteredExpenses.map((expense) => expense.id), [
      10,
      11,
      13,
    ]);

    provider.setPeriod(HistoryPeriod.lastMonth);
    expect(provider.filteredExpenses.map((expense) => expense.id), [12, 14]);

    provider.setCustomPeriod(
      start: DateTime(2026, 6, 30),
      end: DateTime(2026, 7, 10),
    );
    expect(provider.filteredExpenses.map((expense) => expense.id), [14, 15]);
  });

  test('ordena por valor, data e nome da categoria', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: advancedExpenses),
    );
    await provider.loadHistory();
    provider.setCategories(categories);

    provider.setSort(HistorySort.lowestValue);
    expect(provider.filteredExpenses.first.id, 14);
    provider.setSort(HistorySort.highestValue);
    expect(provider.filteredExpenses.first.id, 11);
    provider.setSort(HistorySort.oldest);
    expect(provider.filteredExpenses.first.id, 15);
    provider.setSort(HistorySort.categoryAscending);
    expect(provider.filteredExpenses.first.categoryId, 'food');
    provider.setSort(HistorySort.categoryDescending);
    expect(provider.filteredExpenses.first.categoryId, 'transport');
  });

  test('mantém filtros após recarga, edição e exclusão', () async {
    final repository = FakeHistoryExpenseRepository(expenses: advancedExpenses);
    final provider = HistoryProvider(
      repository: repository,
      now: () => DateTime(2026, 8, 5),
    );
    await provider.loadHistory();
    provider
      ..setCategoryFilter('food')
      ..setPeriod(HistoryPeriod.lastSevenDays)
      ..setValueRange(minimum: 70, maximum: 110);

    await provider.loadHistory();
    expect(provider.filteredExpenses.map((expense) => expense.id), [11, 12]);

    await provider.replaceExpense(
      advancedExpenses[1].copyWith(amount: 65, updatedAt: now),
    );
    expect(provider.filteredExpenses.map((expense) => expense.id), [12]);

    await provider.deleteExpense(12);
    expect(provider.filteredExpenses, isEmpty);
    expect(provider.selectedCategoryId, 'food');
    expect(provider.selectedPeriod, HistoryPeriod.lastSevenDays);
    expect(provider.minimumValue, 70);
    expect(provider.maximumValue, 110);
  });

  test('clearFilters restaura consulta e ordenação padrão', () async {
    final provider = HistoryProvider(
      repository: FakeHistoryExpenseRepository(expenses: advancedExpenses),
    );
    await provider.loadHistory();
    provider
      ..setSearchQuery('assinatura')
      ..setCategoryFilter('food')
      ..setPeriod(HistoryPeriod.today)
      ..setValueRange(minimum: 10, maximum: 100)
      ..setSort(HistorySort.highestValue)
      ..clearFilters();

    expect(provider.hasActiveFilters, isFalse);
    expect(provider.filteredExpenses.length, advancedExpenses.length);
    expect(provider.sort, HistorySort.newest);
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
