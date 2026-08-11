import 'dart:math' as math;

import 'package:quanto_posso/core/database/app_database.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';
import 'package:sqflite/sqflite.dart';

class RecurringExpenseRepository {
  RecurringExpenseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  static const _plansTable = 'recurring_expense_plans';
  static const _expensesTable = 'expenses';

  Future<List<RecurringExpensePlan>> getPlans() async {
    final database = await _database.database;
    final rows = await database.query(_plansTable, orderBy: 'id ASC');
    return rows.map(RecurringExpensePlan.fromMap).toList(growable: false);
  }

  Future<List<Expense>> getExpensesForPlan(int planId) async {
    final database = await _database.database;
    final rows = await database.query(
      _expensesTable,
      where: 'recurring_plan_id = ?',
      whereArgs: [planId],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList(growable: false);
  }

  Future<RecurringExpensePlan?> getPlanById(int planId) async {
    final database = await _database.database;
    final rows = await database.query(
      _plansTable,
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );
    return rows.isEmpty ? null : RecurringExpensePlan.fromMap(rows.single);
  }

  Future<void> updateExpenseAndFuture({
    required Expense expense,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime nextBillingDate,
    DateTime? now,
  }) async {
    final expenseId = expense.id;
    final planId = expense.recurringPlanId;
    if (expenseId == null || planId == null) {
      throw ArgumentError(
        'O lançamento recorrente deve possuir identificadores',
      );
    }
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'Deve ser maior que zero');
    }

    final database = await _database.database;
    await database.transaction((transaction) async {
      final rows = await transaction.query(
        _plansTable,
        where: 'id = ?',
        whereArgs: [planId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Plano recorrente não encontrado');

      final plan = RecurringExpensePlan.fromMap(rows.single);
      final normalizedDescription = description?.trim();
      final effectiveDescription = normalizedDescription?.isEmpty ?? true
          ? null
          : normalizedDescription;
      final updatedAt = now ?? DateTime.now();
      final changedExpenses = await transaction.update(
        _expensesTable,
        {
          'amount': amount,
          'category_id': categoryId,
          'description': effectiveDescription,
          'updated_at': updatedAt.toIso8601String(),
        },
        where: 'id = ? AND recurring_plan_id = ?',
        whereArgs: [expenseId, planId],
      );
      if (changedExpenses == 0) {
        throw StateError('Lançamento recorrente não encontrado');
      }

      final futureStartDate = startDateForNextOccurrence(
        nextBillingDate,
        plan.generatedOccurrences,
      );
      await transaction.update(
        _plansTable,
        {
          'category_id': categoryId,
          'description': effectiveDescription,
          if (plan.type == ExpenseType.subscription) 'amount': amount,
          'start_date': futureStartDate.toIso8601String(),
          'billing_day': nextBillingDate.day,
          'updated_at': updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [planId],
      );
    });
  }

  Future<void> cancelPlan(int planId, {DateTime? now}) async {
    final database = await _database.database;
    final changed = await database.update(
      _plansTable,
      {
        'is_active': 0,
        'status': RecurringPlanStatus.cancelled.storageValue,
        'updated_at': (now ?? DateTime.now()).toIso8601String(),
      },
      where: "id = ? AND is_active = 1 AND status = 'active'",
      whereArgs: [planId],
    );
    if (changed == 0) throw StateError('Plano recorrente não está ativo');
  }

  Future<RecurringExpensePlan> createPlan({
    required ExpenseType type,
    required String categoryId,
    String? description,
    required double amount,
    required DateTime startDate,
    int? totalOccurrences,
    DateTime? now,
  }) async {
    _validate(type, amount, totalOccurrences);
    final createdAt = now ?? DateTime.now();
    final plan = RecurringExpensePlan(
      type: type,
      categoryId: categoryId,
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      amount: amount,
      startDate: startDate,
      billingDay: startDate.day,
      totalOccurrences: totalOccurrences,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final database = await _database.database;
    return database.transaction((transaction) async {
      final id = await transaction.insert(_plansTable, plan.toMap());
      final saved = RecurringExpensePlan.fromMap({...plan.toMap(), 'id': id});
      await _generatePlan(transaction, saved, createdAt);
      final rows = await transaction.query(
        _plansTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return RecurringExpensePlan.fromMap(rows.single);
    });
  }

  Future<int> generateDueOccurrences(DateTime now) async {
    final database = await _database.database;
    return database.transaction((transaction) async {
      final rows = await transaction.query(
        _plansTable,
        where: 'is_active = 1',
        orderBy: 'id ASC',
      );
      var generated = 0;
      for (final row in rows) {
        generated += await _generatePlan(
          transaction,
          RecurringExpensePlan.fromMap(row),
          now,
        );
      }
      return generated;
    });
  }

  Future<int> _generatePlan(
    Transaction transaction,
    RecurringExpensePlan plan,
    DateTime now,
  ) async {
    final planId = plan.id!;
    var generated = plan.generatedOccurrences;
    var inserted = 0;
    for (final number in dueOccurrenceNumbers(plan, now)) {
      final dueDate = planOccurrenceDate(plan, number);
      final expense = Expense(
        amount: await _amountForOccurrence(transaction, plan, number),
        categoryId: plan.categoryId,
        description: plan.description,
        occurredAt: dueDate,
        createdAt: now,
        updatedAt: now,
        recurringPlanId: planId,
        occurrenceNumber: number,
        occurrenceTotal: plan.totalOccurrences,
        recurringType: plan.type,
      );
      final id = await transaction.insert(
        _expensesTable,
        expense.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      generated = number;
      if (id != 0) inserted++;
    }
    final completed =
        plan.totalOccurrences != null && generated >= plan.totalOccurrences!;
    await transaction.update(
      _plansTable,
      {
        'generated_occurrences': generated,
        'is_active': completed ? 0 : 1,
        'status': completed
            ? RecurringPlanStatus.completed.storageValue
            : RecurringPlanStatus.active.storageValue,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
    return inserted;
  }

  static DateTime occurrenceDate(DateTime startDate, int occurrenceNumber) {
    if (occurrenceNumber < 1) {
      throw ArgumentError.value(occurrenceNumber, 'occurrenceNumber');
    }
    final targetMonth = DateTime(
      startDate.year,
      startDate.month + occurrenceNumber - 1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      math.min(startDate.day, lastDay),
    );
  }

  static DateTime planOccurrenceDate(
    RecurringExpensePlan plan,
    int occurrenceNumber,
  ) {
    if (occurrenceNumber < 1) {
      throw ArgumentError.value(occurrenceNumber, 'occurrenceNumber');
    }
    final targetMonth = DateTime(
      plan.startDate.year,
      plan.startDate.month + occurrenceNumber - 1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      math.min(plan.billingDay, lastDay),
    );
  }

  static List<int> dueOccurrenceNumbers(
    RecurringExpensePlan plan,
    DateTime now,
  ) {
    if (!plan.isActive) return const [];
    final numbers = <int>[];
    var number = plan.generatedOccurrences + 1;
    while (plan.totalOccurrences == null || number <= plan.totalOccurrences!) {
      if (planOccurrenceDate(plan, number).isAfter(now)) break;
      numbers.add(number);
      number++;
    }
    return List.unmodifiable(numbers);
  }

  static double occurrenceAmount(
    RecurringExpensePlan plan,
    int occurrenceNumber,
  ) {
    if (plan.type != ExpenseType.installment) return plan.amount;
    final total = plan.totalOccurrences!;
    final cents = (plan.amount * 100).round();
    final base = cents ~/ total;
    final remainder = cents % total;
    return (base + (occurrenceNumber <= remainder ? 1 : 0)) / 100;
  }

  static DateTime startDateForNextOccurrence(
    DateTime nextBillingDate,
    int generatedOccurrences,
  ) {
    return DateTime(
      nextBillingDate.year,
      nextBillingDate.month - generatedOccurrences,
      1,
    );
  }

  static double remainingInstallmentAmount({
    required double planTotal,
    required double generatedTotal,
    required int occurrenceNumber,
    required int totalOccurrences,
  }) {
    final remainingOccurrences = totalOccurrences - occurrenceNumber + 1;
    if (remainingOccurrences <= 0) {
      throw ArgumentError('Não há parcelas futuras para distribuir');
    }
    final remainingCents =
        (planTotal * 100).round() - (generatedTotal * 100).round();
    final base = remainingCents ~/ remainingOccurrences;
    final remainder = remainingCents % remainingOccurrences;
    return (base + (remainder > 0 ? 1 : 0)) / 100;
  }

  Future<double> _amountForOccurrence(
    Transaction transaction,
    RecurringExpensePlan plan,
    int occurrenceNumber,
  ) async {
    if (plan.type != ExpenseType.installment) return plan.amount;
    final result = await transaction.rawQuery(
      '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM $_expensesTable
        WHERE recurring_plan_id = ? AND occurrence_number < ?
      ''',
      [plan.id, occurrenceNumber],
    );
    final generatedTotal = (result.single['total'] as num).toDouble();
    return remainingInstallmentAmount(
      planTotal: plan.amount,
      generatedTotal: generatedTotal,
      occurrenceNumber: occurrenceNumber,
      totalOccurrences: plan.totalOccurrences!,
    );
  }

  void _validate(ExpenseType type, double amount, int? total) {
    if (type == ExpenseType.single) throw ArgumentError('Tipo inválido');
    if (!(amount > 0)) throw ArgumentError('O valor deve ser maior que zero');
    if (type == ExpenseType.installment && (total == null || total <= 1)) {
      throw ArgumentError('O parcelamento deve ter mais de uma parcela');
    }
    if (total != null && total <= 0) {
      throw ArgumentError('A quantidade deve ser maior que zero');
    }
  }
}
