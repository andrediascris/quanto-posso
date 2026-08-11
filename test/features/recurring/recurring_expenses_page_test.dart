import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_theme.dart';
import 'package:quanto_posso/features/recurring/pages/recurring_expenses_page.dart';
import 'package:quanto_posso/features/recurring/widgets/recurring_plan_card.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';

class _SetupRepository extends SetupRepository {
  _SetupRepository(this.categories);
  final List<ExpenseCategory> categories;

  @override
  Future<List<ExpenseCategory>> getCategories() async => categories;

  @override
  Future<UserProfile?> getProfile() async => UserProfile(
    id: 1,
    name: 'André',
    monthlyIncome: 5000,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<bool> hasCompletedInitialSetup() async => true;
}

class _RecurringRepository extends RecurringExpenseRepository {
  _RecurringRepository(this.plans, this.expenses, {this.failOnLoad = false});
  List<RecurringExpensePlan> plans;
  final List<Expense> expenses;
  final bool failOnLoad;

  @override
  Future<List<RecurringExpensePlan>> getPlans() async {
    if (failOnLoad) throw StateError('falha');
    return List.of(plans);
  }

  @override
  Future<List<Expense>> getExpensesForPlan(int planId) async => expenses
      .where((expense) => expense.recurringPlanId == planId)
      .toList(growable: false);

  @override
  Future<void> cancelPlan(int planId, {DateTime? now}) async {
    plans = [
      for (final plan in plans)
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
  final category = ExpenseCategory(
    id: 'leisure',
    name: 'Lazer e entretenimento digital',
    iconCodePoint: Icons.movie_outlined.codePoint,
    iconFontFamily: Icons.movie_outlined.fontFamily ?? 'MaterialIcons',
    colorValue: 0xFF1D1B4F,
    isDefault: true,
    createdAt: now,
  );

  RecurringExpensePlan subscription() => RecurringExpensePlan(
    id: 1,
    type: ExpenseType.subscription,
    categoryId: category.id,
    description: 'Streaming com descrição bastante extensa',
    amount: 49.9,
    startDate: now,
    billingDay: 10,
    generatedOccurrences: 1,
    createdAt: now,
    updatedAt: now,
  );

  RecurringExpensePlan installment() => RecurringExpensePlan(
    id: 2,
    type: ExpenseType.installment,
    categoryId: category.id,
    description: 'Notebook profissional',
    amount: 3600,
    startDate: now,
    billingDay: 10,
    totalOccurrences: 12,
    generatedOccurrences: 4,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required _RecurringRepository repository,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final setup = InitialSetupProvider(
      repository: _SetupRepository([category]),
    );
    await setup.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: setup),
          ChangeNotifierProvider(
            create: (_) => RecurringExpenseProvider(repository: repository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: RecurringExpensesPage(onAddExpense: () async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza resumo, filtros e planos sem overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RecurringRepository([
      subscription(),
      installment(),
    ], const []);
    for (final size in const [Size(360, 800), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      await pumpPage(tester, repository: repository);
      expect(find.text('Recorrências'), findsOneWidget);
      expect(find.text('Comprometido por mês'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Assinaturas'), findsOneWidget);
      expect(find.text('Parcelamentos'), findsOneWidget);
      expect(
        find.text('Streaming com descrição bastante extensa'),
        findsOneWidget,
      );
      expect(find.text('Notebook profissional'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow em $size');
    }
  });

  testWidgets('filtros e estado vazio filtrado funcionam', (tester) async {
    await pumpPage(
      tester,
      repository: _RecurringRepository([subscription()], const []),
    );
    await tester.tap(find.text('Parcelamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum resultado neste filtro.'), findsOneWidget);
    await tester.tap(find.text('Assinaturas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Streaming com descrição bastante extensa'),
      findsOneWidget,
    );
  });

  testWidgets('detalhes mostram histórico e cancelamento confirmado', (
    tester,
  ) async {
    final expense = Expense(
      id: 1,
      amount: 49.9,
      categoryId: category.id,
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
      recurringPlanId: 1,
      occurrenceNumber: 1,
      recurringType: ExpenseType.subscription,
    );
    await pumpPage(
      tester,
      repository: _RecurringRepository([subscription()], [expense]),
    );
    tester.widget<RecurringPlanCard>(find.byType(RecurringPlanCard)).onTap();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Detalhes da recorrência'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Histórico vinculado'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Histórico vinculado'), findsOneWidget);
    expect(find.textContaining('Assinatura — agosto de 2026'), findsOneWidget);
    await tester.tap(find.text('Cancelar assinatura'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar assinatura?'), findsOneWidget);
    expect(
      find.textContaining('Os lançamentos já registrados serão mantidos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar assinatura').last);
    await tester.pumpAndSettle();
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.textContaining('Assinatura — agosto de 2026'), findsOneWidget);
  });

  testWidgets('estado vazio e tema escuro renderizam', (tester) async {
    await pumpPage(
      tester,
      repository: _RecurringRepository(const [], const []),
      themeMode: ThemeMode.dark,
    );
    expect(find.text('Nenhuma recorrência cadastrada.'), findsOneWidget);
    expect(find.text('Adicionar gasto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parcelamento usa encerramento antecipado e preserva o plano', (
    tester,
  ) async {
    await pumpPage(
      tester,
      repository: _RecurringRepository([installment()], const []),
    );
    tester.widget<RecurringPlanCard>(find.byType(RecurringPlanCard)).onTap();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Encerrar parcelamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar parcelamento'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrar parcelamento?'), findsOneWidget);
    expect(
      find.textContaining('As parcelas futuras deixarão de ser geradas.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Encerrar parcelamento').last);
    await tester.pumpAndSettle();
    expect(find.text('Encerrado'), findsOneWidget);
  });

  testWidgets('estado de erro oferece nova tentativa', (tester) async {
    await pumpPage(
      tester,
      repository: _RecurringRepository(const [], const [], failOnLoad: true),
    );
    expect(
      find.text('Não foi possível carregar suas recorrências.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
