import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/app/theme/app_theme.dart';
import 'package:quanto_posso/features/expenses/pages/add_expense_page.dart';
import 'package:quanto_posso/features/expenses/pages/edit_expense_page.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';

void main() {
  final now = DateTime.now();
  final categories = [
    ExpenseCategory(
      id: 'food',
      name: 'Alimentação',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      iconFontFamily: Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
      colorValue: 0xFF1D1B4F,
      isDefault: true,
      createdAt: now,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transporte',
      iconCodePoint: Icons.directions_bus_rounded.codePoint,
      iconFontFamily:
          Icons.directions_bus_rounded.fontFamily ?? 'MaterialIcons',
      colorValue: 0xFFF9A826,
      isDefault: true,
      createdAt: now,
    ),
  ];

  testWidgets('adicionar gasto mantém seleção, data e validação', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: AddExpensePage(categories: categories, onSave: _emptyAddSave),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adicionar gasto'), findsOneWidget);
    expect(find.text('Novo gasto'), findsOneWidget);
    expect(find.text('Valor do gasto'), findsOneWidget);
    expect(find.text('Único'), findsOneWidget);
    expect(find.text('Um gasto feito apenas uma vez.'), findsOneWidget);
    expect(find.text('Número de parcelas'), findsNothing);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Descrição opcional'), findsOneWidget);
    expect(find.text('Salvar gasto'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar categoria'), findsOneWidget);
    await tester.tap(find.text('Transporte'));
    await tester.pumpAndSettle();
    expect(find.text('Transporte'), findsOneWidget);

    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
    await tester.pumpAndSettle();

    final saveButton = find.text('Salvar gasto');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Informe o valor do gasto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading de adicionar gasto bloqueia clique duplicado', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    var saveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddExpensePage(
          categories: categories,
          onSave:
              ({
                required amount,
                required categoryId,
                description,
                required occurredAt,
              }) {
                saveCalls++;
                return completer.future;
              },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, '25,90');
    final saveButton = find.text('Salvar gasto');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    final primaryButton = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    expect(primaryButton.isLoading, isTrue);
    expect(primaryButton.onPressed, isNull);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(saveCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
    expect(saveCalls, 1);
  });

  testWidgets('configura e salva uma assinatura mensal', (
    WidgetTester tester,
  ) async {
    ExpenseType? savedType;
    int? savedTotal;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddExpensePage(
          categories: categories,
          onSave: _emptyAddSave,
          onSaveRecurring:
              ({
                required type,
                required amount,
                required categoryId,
                description,
                required startDate,
                totalOccurrences,
              }) async {
                savedType = type;
                savedTotal = totalOccurrences;
              },
        ),
      ),
    );

    await tester.tap(find.text('Assinatura'));
    await tester.pumpAndSettle();
    expect(find.text('Valor mensal'), findsOneWidget);
    expect(find.text('Até cancelar'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '29,90');
    await tester.pump();
    expect(find.textContaining('29,90 por mês'), findsOneWidget);

    await tester.ensureVisible(find.text('Salvar gasto'));
    await tester.tap(find.text('Salvar gasto'));
    await tester.pumpAndSettle();
    expect(savedType, ExpenseType.subscription);
    expect(savedTotal, isNull);
  });

  testWidgets('configura parcelamento e exibe resumo', (
    WidgetTester tester,
  ) async {
    ExpenseType? savedType;
    int? savedTotal;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddExpensePage(
          categories: categories,
          onSave: _emptyAddSave,
          onSaveRecurring:
              ({
                required type,
                required amount,
                required categoryId,
                description,
                required startDate,
                totalOccurrences,
              }) async {
                savedType = type;
                savedTotal = totalOccurrences;
              },
        ),
      ),
    );

    await tester.tap(find.text('Parcelado'));
    await tester.pumpAndSettle();
    expect(find.text('Valor total da compra'), findsOneWidget);
    expect(find.text('Número de parcelas'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '100,00');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número de parcelas'),
      '3',
    );
    await tester.pump();
    expect(find.textContaining('3 parcelas de'), findsOneWidget);
    expect(find.textContaining('33,33'), findsOneWidget);

    await tester.ensureVisible(find.text('Salvar gasto'));
    await tester.tap(find.text('Salvar gasto'));
    await tester.pumpAndSettle();
    expect(savedType, ExpenseType.installment);
    expect(savedTotal, 3);
  });

  testWidgets('parcelamento rejeita uma unica parcela', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddExpensePage(
          categories: categories,
          onSave: _emptyAddSave,
          onSaveRecurring:
              ({
                required type,
                required amount,
                required categoryId,
                description,
                required startDate,
                totalOccurrences,
              }) async {},
        ),
      ),
    );
    await tester.tap(find.text('Parcelado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '100,00');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número de parcelas'),
      '1',
    );
    await tester.ensureVisible(find.text('Salvar gasto'));
    await tester.tap(find.text('Salvar gasto'));
    await tester.pump();
    expect(find.text('Para uma parcela, utilize o tipo Único'), findsOneWidget);
  });

  testWidgets('adicionar e editar renderizam no tema escuro sem overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final expense = Expense(
      id: 1,
      amount: 42.5,
      categoryId: 'food',
      description: 'Almoço',
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    );

    for (final size in const [Size(360, 800), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: AddExpensePage(categories: categories, onSave: _emptyAddSave),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Adicionar em $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: EditExpensePage(
            expense: expense,
            categories: categories,
            onSave: _emptyEditSave,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Atualize o lançamento'), findsOneWidget);
      expect(find.text('42,50'), findsOneWidget);
      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Editar em $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<void> _emptyAddSave({
  required double amount,
  required String categoryId,
  String? description,
  required DateTime occurredAt,
}) async {}

Future<void> _emptyEditSave({
  required Expense expense,
  required double amount,
  required String categoryId,
  String? description,
  required DateTime occurredAt,
}) async {}
