import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

void main() {
  RecurringExpensePlan plan({
    ExpenseType type = ExpenseType.installment,
    DateTime? startDate,
    double amount = 100,
    int? totalOccurrences = 3,
    int generatedOccurrences = 0,
    bool isActive = true,
  }) {
    final createdAt = DateTime(2026, 1, 1);
    final start = startDate ?? DateTime(2026, 1, 31);
    return RecurringExpensePlan(
      id: 1,
      type: type,
      categoryId: 'food',
      amount: amount,
      startDate: start,
      billingDay: start.day,
      totalOccurrences: totalOccurrences,
      generatedOccurrences: generatedOccurrences,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('calendario mensal', () {
    test('ajusta dias 29, 30 e 31 ao ultimo dia do mes', () {
      expect(
        RecurringExpenseRepository.occurrenceDate(DateTime(2025, 1, 29), 2),
        DateTime(2025, 2, 28),
      );
      expect(
        RecurringExpenseRepository.occurrenceDate(DateTime(2025, 1, 30), 2),
        DateTime(2025, 2, 28),
      );
      expect(
        RecurringExpenseRepository.occurrenceDate(DateTime(2025, 1, 31), 4),
        DateTime(2025, 4, 30),
      );
    });

    test('respeita fevereiro em ano bissexto', () {
      expect(
        RecurringExpenseRepository.occurrenceDate(DateTime(2024, 1, 31), 2),
        DateTime(2024, 2, 29),
      );
    });
  });

  test('parcelas preservam exatamente o total em centavos', () {
    final installment = plan(amount: 100, totalOccurrences: 3);
    final amounts = [
      for (var number = 1; number <= 3; number++)
        RecurringExpenseRepository.occurrenceAmount(installment, number),
    ];
    expect(amounts, [33.34, 33.33, 33.33]);
    expect(
      amounts.map((value) => (value * 100).round()).reduce((a, b) => a + b),
      10000,
    );
  });

  test('redistribuição futura preserva histórico e total em centavos', () {
    const total = 100.0;
    const generatedTotal = 66.67;
    final third = RecurringExpenseRepository.remainingInstallmentAmount(
      planTotal: total,
      generatedTotal: generatedTotal,
      occurrenceNumber: 3,
      totalOccurrences: 4,
    );
    final fourth = RecurringExpenseRepository.remainingInstallmentAmount(
      planTotal: total,
      generatedTotal: generatedTotal + third,
      occurrenceNumber: 4,
      totalOccurrences: 4,
    );

    expect((third * 100).round(), 1667);
    expect((fourth * 100).round(), 1666);
    expect(
      (generatedTotal * 100).round() +
          (third * 100).round() +
          (fourth * 100).round(),
      10000,
    );
  });

  test('nova cobrança mantém ocorrências anteriores no mesmo calendário', () {
    final start = RecurringExpenseRepository.startDateForNextOccurrence(
      DateTime(2026, 5, 31),
      3,
    );
    final adjustedPlan = RecurringExpensePlan(
      id: 1,
      type: ExpenseType.installment,
      categoryId: 'food',
      amount: 100,
      startDate: start,
      billingDay: 31,
      totalOccurrences: 4,
      generatedOccurrences: 3,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(
      RecurringExpenseRepository.planOccurrenceDate(adjustedPlan, 4),
      DateTime(2026, 5, 31),
    );
  });

  test('assinatura repete o valor mensal sem divisao', () {
    final subscription = plan(
      type: ExpenseType.subscription,
      amount: 29.9,
      totalOccurrences: null,
    );
    expect(RecurringExpenseRepository.occurrenceAmount(subscription, 7), 29.9);
  });

  test('assinatura limitada encerra a sequencia no mes configurado', () {
    final subscription = plan(
      type: ExpenseType.subscription,
      startDate: DateTime(2026, 1, 10),
      totalOccurrences: 2,
    );
    expect(
      RecurringExpenseRepository.dueOccurrenceNumbers(
        subscription,
        DateTime(2026, 12, 31),
      ),
      [1, 2],
    );
  });

  test('assinatura sem prazo continua ativa nos meses seguintes', () {
    final subscription = plan(
      type: ExpenseType.subscription,
      startDate: DateTime(2026, 1, 10),
      totalOccurrences: null,
      generatedOccurrences: 2,
    );
    expect(
      RecurringExpenseRepository.dueOccurrenceNumbers(
        subscription,
        DateTime(2026, 4, 10),
      ),
      [3, 4],
    );
  });

  group('recuperacao e idempotencia logica', () {
    test('recupera todos os meses vencidos a partir do contador salvo', () {
      final overdue = plan(
        startDate: DateTime(2026, 1, 31),
        totalOccurrences: 6,
        generatedOccurrences: 1,
      );
      expect(
        RecurringExpenseRepository.dueOccurrenceNumbers(
          overdue,
          DateTime(2026, 4, 30),
        ),
        [2, 3, 4],
      );
    });

    test('nao retorna ocorrencias ja geradas ou futuras', () {
      final current = plan(totalOccurrences: 6, generatedOccurrences: 4);
      expect(
        RecurringExpenseRepository.dueOccurrenceNumbers(
          current,
          DateTime(2026, 4, 30),
        ),
        isEmpty,
      );
    });

    test('plano concluido nao gera novas parcelas', () {
      final completed = plan(totalOccurrences: 3, generatedOccurrences: 3);
      expect(
        RecurringExpenseRepository.dueOccurrenceNumbers(
          completed,
          DateTime(2027, 1, 1),
        ),
        isEmpty,
      );
    });

    test('plano inativo nao gera novas ocorrencias', () {
      final inactive = plan(
        type: ExpenseType.subscription,
        totalOccurrences: null,
        isActive: false,
      );
      expect(
        RecurringExpenseRepository.dueOccurrenceNumbers(
          inactive,
          DateTime(2027, 1, 1),
        ),
        isEmpty,
      );
    });

    test('exclusao individual nao recua o contador do plano', () {
      final afterDeletion = plan(totalOccurrences: 5, generatedOccurrences: 3);
      expect(
        RecurringExpenseRepository.dueOccurrenceNumbers(
          afterDeletion,
          DateTime(2026, 3, 31),
        ),
        isEmpty,
      );
    });
  });
}
