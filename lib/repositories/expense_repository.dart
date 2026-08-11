import 'package:quanto_posso/core/database/app_database.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';

class ExpenseRepository {
  ExpenseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  static const _expensesTable = 'expenses';
  static const _defaultOrder = 'occurred_at DESC, id DESC';

  final AppDatabase _database;

  Future<Expense> createExpense(Expense expense) async {
    _validateAmount(expense.amount);

    final normalizedExpense = _withNormalizedDescription(expense);
    final values = normalizedExpense.toMap()..remove('id');
    final database = await _database.database;
    final id = await database.insert(_expensesTable, values);

    return normalizedExpense.copyWith(id: id);
  }

  Future<void> updateExpense(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError.value(id, 'expense.id', 'O id é obrigatório');
    }

    _validateAmount(expense.amount);

    final normalizedExpense = _withNormalizedDescription(expense);
    final updatedAt = DateTime.now();
    final database = await _database.database;
    final updatedRows = await database.update(
      _expensesTable,
      <String, Object?>{
        'amount': normalizedExpense.amount,
        'category_id': normalizedExpense.categoryId,
        'description': normalizedExpense.description,
        'occurred_at': normalizedExpense.occurredAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updatedRows == 0) {
      throw StateError('Despesa não encontrada');
    }
  }

  Future<void> deleteExpense(int id) async {
    final database = await _database.database;
    final deletedRows = await database.delete(
      _expensesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedRows == 0) {
      throw StateError('Despesa não encontrada');
    }
  }

  Future<Expense?> getExpenseById(int id) async {
    final database = await _database.database;
    final expenses = await database.query(
      _expensesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (expenses.isEmpty) {
      return null;
    }

    return Expense.fromMap(expenses.first);
  }

  Future<List<Expense>> getAllExpenses() async {
    final database = await _database.database;
    final expenses = await database.query(
      _expensesTable,
      orderBy: _defaultOrder,
    );

    return expenses.map(Expense.fromMap).toList(growable: false);
  }

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Deve ser maior que zero');
    }

    final database = await _database.database;
    final expenses = await database.query(
      _expensesTable,
      orderBy: _defaultOrder,
      limit: limit,
    );

    return expenses.map(Expense.fromMap).toList(growable: false);
  }

  Future<List<Expense>> getExpensesBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    _validatePeriod(start, end);

    final database = await _database.database;
    final expenses = await database.query(
      _expensesTable,
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: _defaultOrder,
    );

    return expenses.map(Expense.fromMap).toList(growable: false);
  }

  Future<double> getTotalBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    _validatePeriod(start, end);

    final database = await _database.database;
    final result = await database.rawQuery(
      '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM $_expensesTable
        WHERE occurred_at >= ?
          AND occurred_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final total = result.first['total'];

    return total is num ? total.toDouble() : 0.0;
  }

  Future<Map<String, double>> getTotalsByCategory({
    required DateTime start,
    required DateTime end,
  }) async {
    _validatePeriod(start, end);

    final database = await _database.database;
    final result = await database.rawQuery(
      '''
        SELECT category_id, COALESCE(SUM(amount), 0) AS total
        FROM $_expensesTable
        WHERE occurred_at >= ?
          AND occurred_at < ?
        GROUP BY category_id
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final totals = <String, double>{};

    for (final row in result) {
      final categoryId = row['category_id'] as String;
      final total = row['total'];
      totals[categoryId] = (total as num).toDouble();
    }

    return totals;
  }

  Future<List<DailyExpenseTotal>> getDailyTotalsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    _validatePeriod(start, end);

    final database = await _database.database;
    final result = await database.rawQuery(
      '''
        SELECT
          date(occurred_at) AS expense_day,
          COALESCE(SUM(amount), 0) AS total
        FROM $_expensesTable
        WHERE occurred_at >= ?
          AND occurred_at < ?
        GROUP BY date(occurred_at)
        ORDER BY expense_day ASC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return result
        .map(
          (row) => DailyExpenseTotal(
            day: DateTime.parse(row['expense_day'] as String),
            total: (row['total'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  Future<List<MonthlyExpenseSummary>> getMonthlySummaries({
    required DateTime startMonth,
    required DateTime endMonth,
  }) async {
    final normalizedStart = DateTime(startMonth.year, startMonth.month);
    final normalizedEnd = DateTime(endMonth.year, endMonth.month);
    if (normalizedStart.isAfter(normalizedEnd)) {
      throw ArgumentError(
        'O mês inicial deve ser anterior ou igual ao mês final',
      );
    }
    final exclusiveEnd = DateTime(normalizedEnd.year, normalizedEnd.month + 1);
    final database = await _database.database;
    final result = await database.rawQuery(
      '''
        SELECT
          strftime('%Y-%m', occurred_at) AS expense_month,
          COALESCE(SUM(amount), 0) AS total,
          COUNT(*) AS expense_count
        FROM $_expensesTable
        WHERE occurred_at >= ?
          AND occurred_at < ?
        GROUP BY strftime('%Y-%m', occurred_at)
        ORDER BY expense_month ASC
      ''',
      [normalizedStart.toIso8601String(), exclusiveEnd.toIso8601String()],
    );

    return result
        .map((row) {
          final monthParts = (row['expense_month'] as String).split('-');
          return MonthlyExpenseSummary(
            month: DateTime(
              int.parse(monthParts.first),
              int.parse(monthParts.last),
            ),
            total: (row['total'] as num).toDouble(),
            expenseCount: (row['expense_count'] as num).toInt(),
          );
        })
        .toList(growable: false);
  }

  Future<Expense?> getHighestExpenseBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    _validatePeriod(start, end);
    final database = await _database.database;
    final result = await database.query(
      _expensesTable,
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'amount DESC, occurred_at DESC',
      limit: 1,
    );
    return result.isEmpty ? null : Expense.fromMap(result.first);
  }

  Expense _withNormalizedDescription(Expense expense) {
    final normalizedDescription = expense.description?.trim();

    return expense.copyWith(
      description: normalizedDescription,
      clearDescription:
          normalizedDescription == null || normalizedDescription.isEmpty,
    );
  }

  void _validateAmount(double amount) {
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'Deve ser maior que zero');
    }
  }

  void _validatePeriod(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      throw ArgumentError('A data inicial deve ser anterior ou igual à final');
    }
  }
}
