import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/app/app.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/monthly_expense_summary.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/models/reminder_preferences.dart';
import 'package:quanto_posso/models/budget_alert_preferences.dart';
import 'package:quanto_posso/models/app_backup.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/notification_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';
import 'package:quanto_posso/shared/cards/budget_alert_settings_card.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/charts/monthly_expense_line_chart.dart';

class FakeSetupRepository extends SetupRepository {
  FakeSetupRepository({
    this.profile,
    List<ExpenseCategory> categories = const [],
  }) : _categories = List.of(categories);

  UserProfile? profile;
  List<ExpenseCategory> _categories;
  var _nextCategoryId = 1;

  UserProfile? get savedProfile => profile;
  List<ExpenseCategory> get savedCategories => List.unmodifiable(_categories);

  @override
  Future<bool> hasCompletedInitialSetup() async {
    return profile != null && _categories.isNotEmpty;
  }

  @override
  Future<UserProfile?> getProfile() async => profile;

  @override
  Future<List<ExpenseCategory>> getCategories() async {
    return List.unmodifiable(_categories);
  }

  @override
  Future<void> saveInitialSetup({
    required UserProfile profile,
    required List<ExpenseCategory> categories,
  }) async {
    this.profile = profile;
    _categories = List.of(categories);
  }

  @override
  Future<void> clearInitialSetup() async {
    profile = null;
    _categories = [];
  }

  @override
  Future<bool> categoryNameExists({
    required String name,
    String? excludingId,
  }) async {
    final normalizedName = name.trim().toLowerCase();
    return _categories.any(
      (category) =>
          category.id != excludingId &&
          category.name.toLowerCase() == normalizedName,
    );
  }

  @override
  Future<ExpenseCategory> createCategory({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int colorValue,
  }) async {
    final category = ExpenseCategory(
      id: 'category_${_nextCategoryId++}',
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      colorValue: colorValue,
      isDefault: false,
      createdAt: DateTime(2026),
    );
    _categories.add(category);
    return category;
  }
}

class FakeExpenseRepository extends ExpenseRepository {
  final List<Expense> expenses = [];

  @override
  Future<Expense> createExpense(Expense expense) async {
    final savedExpense = expense.copyWith(id: expenses.length + 1);
    expenses.add(savedExpense);
    return savedExpense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index < 0) throw StateError('Gasto n\u00e3o encontrado');
    expenses[index] = expense;
  }

  @override
  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    return expenses.take(limit).toList(growable: false);
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return List.unmodifiable(expenses);
  }

  @override
  Future<void> deleteExpense(int id) async {
    expenses.removeWhere((expense) => expense.id == id);
  }

  @override
  Future<double> getTotalBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    return expenses
        .where(
          (expense) =>
              !expense.occurredAt.isBefore(start) &&
              expense.occurredAt.isBefore(end),
        )
        .fold<double>(0.0, (total, expense) => total + expense.amount);
  }

  @override
  Future<Map<String, double>> getTotalsByCategory({
    required DateTime start,
    required DateTime end,
  }) async {
    final totals = <String, double>{};
    for (final expense in expenses.where(
      (expense) =>
          !expense.occurredAt.isBefore(start) &&
          expense.occurredAt.isBefore(end),
    )) {
      totals.update(
        expense.categoryId,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  @override
  Future<List<DailyExpenseTotal>> getDailyTotalsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final totals = <DateTime, double>{};
    for (final expense in expenses.where(
      (expense) =>
          !expense.occurredAt.isBefore(start) &&
          expense.occurredAt.isBefore(end),
    )) {
      final day = DateTime(
        expense.occurredAt.year,
        expense.occurredAt.month,
        expense.occurredAt.day,
      );
      totals.update(
        day,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final result = [
      for (final entry in totals.entries)
        DailyExpenseTotal(day: entry.key, total: entry.value),
    ]..sort((first, second) => first.day.compareTo(second.day));
    return result;
  }

  @override
  Future<List<MonthlyExpenseSummary>> getMonthlySummaries({
    required DateTime startMonth,
    required DateTime endMonth,
  }) async {
    final totals = <String, MonthlyExpenseSummary>{};
    for (final expense in expenses) {
      final month = DateTime(expense.occurredAt.year, expense.occurredAt.month);
      final normalizedStart = DateTime(startMonth.year, startMonth.month);
      final normalizedEnd = DateTime(endMonth.year, endMonth.month);
      if (month.isBefore(normalizedStart) || month.isAfter(normalizedEnd)) {
        continue;
      }
      final key = '${month.year}-${month.month}';
      final current = totals[key];
      totals[key] = MonthlyExpenseSummary(
        month: month,
        total: (current?.total ?? 0) + expense.amount,
        expenseCount: (current?.expenseCount ?? 0) + 1,
      );
    }
    final result = totals.values.toList()
      ..sort((first, second) => first.month.compareTo(second.month));
    return result;
  }

  @override
  Future<Expense?> getHighestExpenseBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final candidates =
        expenses
            .where(
              (expense) =>
                  !expense.occurredAt.isBefore(start) &&
                  expense.occurredAt.isBefore(end),
            )
            .toList()
          ..sort((first, second) {
            final amountComparison = second.amount.compareTo(first.amount);
            if (amountComparison != 0) return amountComparison;
            return second.occurredAt.compareTo(first.occurredAt);
          });
    return candidates.isEmpty ? null : candidates.first;
  }
}

class FakeWidgetPreferencesRepository extends PreferencesRepository {
  ThemeMode mode = ThemeMode.light;
  ReminderPreferences reminderPreferences = ReminderPreferences.defaults;
  BudgetAlertPreferences budgetAlertPreferences =
      BudgetAlertPreferences.defaults;

  @override
  Future<ThemeMode> getThemeMode() async => mode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    this.mode = mode;
  }

  @override
  Future<ReminderPreferences> getReminderPreferences() async =>
      reminderPreferences;

  @override
  Future<void> saveReminderPreferences(ReminderPreferences preferences) async {
    reminderPreferences = preferences;
  }

  @override
  Future<BudgetAlertPreferences> getBudgetAlertPreferences() async =>
      budgetAlertPreferences;

  @override
  Future<void> saveBudgetAlertPreferences(
    BudgetAlertPreferences preferences,
  ) async {
    budgetAlertPreferences = preferences;
  }

  @override
  Future<void> clear() async {
    mode = ThemeMode.light;
  }
}

class FakeWidgetNotificationScheduler implements NotificationScheduler {
  bool permissionGranted = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<void> showBudgetWarning({
    required int percentage,
    required double remainingAmount,
  }) async {}

  @override
  Future<void> showBudgetLimitExceeded({
    required double exceededAmount,
  }) async {}
}

class FakeWidgetBackupRepository extends BackupRepository {
  @override
  Future<BackupExportResult> exportAndShareBackup() async {
    return BackupExportResult(
      fileName: 'quanto_posso_backup_2026-08-05_0915.json',
      filePath: 'temporary/backup.json',
      exportedAt: DateTime(2026, 8, 5, 9, 15),
      categoryCount: 1,
      expenseCount: 0,
    );
  }

  @override
  Future<BackupImportPreview?> selectAndValidateBackup() async {
    final exportedAt = DateTime(2026, 8, 5, 9, 15);
    final backup = AppBackup(
      backupVersion: 1,
      appName: 'Quanto Posso',
      exportedAt: exportedAt,
      profile: const {'name': 'Andr\u00e9'},
      categories: const [],
      expenses: const [],
      preferences: const {},
    );
    return BackupImportPreview(
      backup: backup,
      fileName: 'quanto_posso_backup_2026-08-05_0915.json',
      categoryCount: 1,
      expenseCount: 2,
      profileName: 'Andr\u00e9',
      monthlyIncome: 3500,
      exportedAt: exportedAt,
    );
  }
}

void main() {
  testWidgets('tema escuro renderiza as quatro telas principais', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final preferencesRepository = FakeWidgetPreferencesRepository()
      ..mode = ThemeMode.dark;
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'Andr\u00e9',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimenta\u00e7\u00e3o',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: AppColors.primary.toARGB32(),
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: preferencesRepository,
      ),
    );
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byType(Scaffold).first);
    final homeTheme = Theme.of(homeContext);
    expect(homeTheme.brightness, Brightness.dark);
    expect(homeTheme.scaffoldBackgroundColor, AppColors.backgroundDark);
    expect(
      homeTheme.colorScheme.surface,
      isNot(homeTheme.scaffoldBackgroundColor),
    );
    expect(
      homeTheme.colorScheme.onSurface,
      isNot(homeTheme.colorScheme.surface),
    );

    for (final destination in [
      'Dashboard',
      'Hist\u00f3rico',
      'Configura\u00e7\u00f5es',
      'Home',
    ]) {
      await tester.tap(find.byTooltip(destination));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
    }

    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
    final unselectedIcon = tester.widget<Icon>(
      find.byIcon(Icons.pie_chart_outline_rounded),
    );
    expect(selectedIcon.color, isNot(unselectedIcon.color));
  });

  testWidgets('preferência antiga do sistema abre o aplicativo no tema claro', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'Andr\u00e9',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimenta\u00e7\u00e3o',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: AppColors.primary.toARGB32(),
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository()
          ..mode = ThemeMode.system,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });

  testWidgets('modos claro e escuro ignoram o brilho oposto do sistema', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final setupRepository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'Andr\u00e9',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimenta\u00e7\u00e3o',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: AppColors.primary.toARGB32(),
          isDefault: true,
          createdAt: now,
        ),
      ],
    );

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: setupRepository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository()
          ..mode = ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: setupRepository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository()
          ..mode = ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('abre a tela de backup pelas configura\u00e7\u00f5es', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'Andr\u00e9',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimenta\u00e7\u00e3o',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
        backupRepository: FakeWidgetBackupRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    final backupItem = find.text('Backup e dados');
    await tester.ensureVisible(backupItem);
    await tester.tap(backupItem);
    await tester.pumpAndSettle();

    expect(find.text('Proteja seus dados'), findsOneWidget);
    expect(find.text('Criar backup'), findsOneWidget);
    expect(find.text('Criar e compartilhar'), findsOneWidget);
    expect(find.text('Restaurar backup'), findsOneWidget);
    final selectButton = tester.widget<PrimaryButton>(
      find
          .ancestor(
            of: find.text('Selecionar arquivo'),
            matching: find.byType(PrimaryButton),
          )
          .first,
    );
    expect(selectButton.onPressed, isNotNull);
    await tester.ensureVisible(find.text('Selecionar arquivo'));
    await tester.tap(find.text('Selecionar arquivo'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurar backup'), findsWidgets);
    expect(find.text('Resumo do backup'), findsOneWidget);
    expect(find.text('Andr\u00e9'), findsOneWidget);
    expect(
      find.text('Os dados atuais ser\u00e3o substitu\u00eddos.'),
      findsOneWidget,
    );
    var restoreButton = tester.widget<PrimaryButton>(
      find.ancestor(
        of: find.text('Restaurar dados'),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(restoreButton.onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    restoreButton = tester.widget<PrimaryButton>(
      find.ancestor(
        of: find.text('Restaurar dados'),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(restoreButton.onPressed, isNotNull);
    await tester.ensureVisible(find.text('Restaurar dados'));
    await tester.tap(find.text('Restaurar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar restaura\u00e7\u00e3o?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('conclui o fluxo de primeiro acesso', (
    WidgetTester tester,
  ) async {
    final repository = FakeSetupRepository();
    final expenseRepository = FakeExpenseRepository();

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: expenseRepository,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PrimaryButton));

    expect(find.text('Quanto Posso'), findsOneWidget);
    expect(find.text('Cuide melhor do seu dinheiro'), findsOneWidget);

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'André');
    await tester.enterText(fields.at(1), '3500');

    final continueButton = find.text('Continuar');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Organize seus gastos'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Tudo pronto!'), findsOneWidget);
    expect(find.text('Ir para a Home'), findsOneWidget);

    await tester.tap(find.text('Ir para a Home'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, André!'), findsOneWidget);
    expect(repository.savedProfile?.name, 'André');
    expect(repository.savedCategories, isNotEmpty);
  });

  testWidgets('abre a home quando o usuário já está configurado', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );
    final expenseRepository = FakeExpenseRepository();

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: expenseRepository,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, André!'), findsOneWidget);
    expect(find.text('Veja como estão seus gastos hoje.'), findsOneWidget);
    expect(find.text('Saldo atual'), findsOneWidget);
    expect(find.text('Gasto neste mês'), findsOneWidget);
    expect(find.text('Renda mensal'), findsOneWidget);
    expect(find.text('Gastos recentes'), findsOneWidget);
    expect(find.text('Ver histórico'), findsOneWidget);
    expect(find.text('Nenhum gasto registrado hoje.'), findsOneWidget);
    expect(find.byTooltip('Adicionar gasto'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
    expect(find.text('Saiba quanto você ainda pode gastar.'), findsNothing);
  });

  testWidgets('Home permanece responsiva em telas mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final now = DateTime(2026);

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André da Silva',
            monthlyIncome: 123456.78,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentação',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    const mobileSizes = [Size(360, 800), Size(412, 915), Size(411, 923)];
    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();

      expect(find.text('Olá, André!'), findsOneWidget);
      expect(find.text('Saldo atual'), findsOneWidget);
      expect(find.text('Gasto neste mês'), findsOneWidget);
      expect(find.text('Renda mensal'), findsOneWidget);
      expect(find.text('Gastos recentes'), findsOneWidget);
      expect(find.text('Nenhum gasto registrado hoje.'), findsOneWidget);
      expect(find.byTooltip('Adicionar gasto'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Falha no tamanho $size');
    }
  });

  testWidgets('abre o formulário de novo gasto pela Home', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.byTooltip('Adicionar gasto');
    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Adicionar gasto'), findsOneWidget);
    expect(find.text('Novo gasto'), findsOneWidget);
    expect(find.text('Valor do gasto'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Descrição opcional'), findsOneWidget);
    expect(find.text('Salvar gasto'), findsOneWidget);
  });

  testWidgets('abre a aba de histórico pelo menu inferior', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, André!'), findsOneWidget);

    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Histórico'), findsWidgets);
    expect(find.text('Consulte e gerencie seus gastos.'), findsOneWidget);
    expect(find.text('Pesquisar'), findsOneWidget);
    expect(find.text('Buscar por descrição'), findsOneWidget);
    expect(find.byTooltip('Abrir filtros avançados'), findsOneWidget);
    expect(find.text('Todo o período'), findsOneWidget);
    expect(find.text('Todas categorias'), findsOneWidget);
    expect(find.text('Mais recentes'), findsOneWidget);
    expect(find.text('0 gastos registrados'), findsOneWidget);
    expect(find.text('Total filtrado'), findsOneWidget);
    expect(find.text('Nenhum gasto registrado.'), findsOneWidget);
    expect(find.byTooltip('Adicionar gasto'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'inexistente');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum gasto encontrado.'), findsOneWidget);
    expect(
      find.text('Altere ou limpe os filtros para ver outros resultados.'),
      findsOneWidget,
    );
    expect(find.text('Limpar'), findsOneWidget);
    expect(find.text('Limpar filtros', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Histórico permanece responsivo em telas mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    final now = DateTime.now();
    final category = ExpenseCategory(
      id: 'food',
      name: 'Alimentação e restaurantes favoritos',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      iconFontFamily: Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
      colorValue: 0xFF1D1B4F,
      isDefault: true,
      createdAt: now,
    );
    final expenseRepository = FakeExpenseRepository();
    expenseRepository.expenses.addAll([
      Expense(
        id: 1,
        amount: 123456.78,
        categoryId: category.id,
        description: 'Descrição extensa para validar responsividade do item',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: 2,
        amount: 9876543.21,
        categoryId: category.id,
        description: 'Assinatura com uma descrição muito longa',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        recurringPlanId: 1,
        occurrenceNumber: 1,
        recurringType: ExpenseType.subscription,
      ),
      Expense(
        id: 3,
        amount: 3333333.33,
        categoryId: category.id,
        description: 'Compra parcelada com uma descrição muito longa',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        recurringPlanId: 2,
        occurrenceNumber: 12,
        occurrenceTotal: 120,
        recurringType: ExpenseType.installment,
      ),
    ]);

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 200000,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [category],
        ),
        expenseRepository: expenseRepository,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    const mobileSizes = [Size(360, 800), Size(412, 915), Size(411, 923)];
    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();

      expect(find.text('Consulte e gerencie seus gastos.'), findsOneWidget);
      expect(find.byTooltip('Abrir filtros avançados'), findsOneWidget);
      expect(find.text('Todo o período'), findsOneWidget);
      expect(find.text('Todas categorias'), findsOneWidget);
      expect(find.text('Mais recentes'), findsOneWidget);
      expect(find.text('3 gastos registrados'), findsOneWidget);
      expect(find.text('Assinatura'), findsOneWidget);
      expect(find.textContaining('123.456,78'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Parcela 12 de 120'),
        AppSpacing.buttonHeight,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Parcela 12 de 120'), findsOneWidget);
      expect(find.byTooltip('Editar gasto'), findsWidgets);
      expect(find.byTooltip('Excluir gasto'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Falha no tamanho $size');
    }
  });

  testWidgets('filtros rápidos aplicam período, categoria e ordenação', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final now = DateTime.now();
    final categories = [
      ExpenseCategory(
        id: 'food',
        name: 'Alimentação com nome muito extenso',
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        iconFontFamily: Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFF1D1B4F,
        isDefault: true,
        createdAt: now,
      ),
      ExpenseCategory(
        id: 'transport',
        name: 'Transporte',
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        iconFontFamily:
            Icons.directions_car_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFFFFB020,
        isDefault: true,
        createdAt: now,
      ),
    ];
    final expenseRepository = FakeExpenseRepository()
      ..expenses.addAll([
        Expense(
          id: 1,
          amount: 10,
          categoryId: 'food',
          description: 'Valor baixo',
          occurredAt: DateTime(now.year, now.month, 2),
          createdAt: now,
          updatedAt: now,
        ),
        Expense(
          id: 2,
          amount: 100,
          categoryId: 'transport',
          description: 'Valor alto',
          occurredAt: DateTime(now.year, now.month, 3),
          createdAt: now,
          updatedAt: now,
        ),
        Expense(
          id: 3,
          amount: 50,
          categoryId: 'food',
          description: 'Valor antigo',
          occurredAt: DateTime(now.year - 1, now.month, 1),
          createdAt: now,
          updatedAt: now,
        ),
      ]);

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 5000,
            createdAt: now,
            updatedAt: now,
          ),
          categories: categories,
        ),
        expenseRepository: expenseRepository,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todo o período'));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar período'), findsOneWidget);
    expect(find.text('Filtros avançados'), findsNothing);
    await tester.tap(find.text('Este mês'));
    await tester.pumpAndSettle();
    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('2 gastos encontrados'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Selecionar categoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Selecionar categoria'));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar categoria'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Transporte'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Transporte'), findsWidgets);
    expect(find.text('1 gastos encontrados'), findsOneWidget);
    expect(find.textContaining('100,00'), findsWidgets);

    await tester.ensureVisible(find.byTooltip('Selecionar categoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Selecionar categoria'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Todas categorias'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Alterar ordenação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Alterar ordenação'));
    await tester.pumpAndSettle();
    expect(find.text('Alterar ordenação'), findsOneWidget);
    await tester.tap(find.text('Maior valor'));
    await tester.pumpAndSettle();
    expect(find.text('Maior valor'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Valor alto')).dy,
      lessThan(tester.getTopLeft(find.text('Valor baixo')).dy),
    );

    await tester.tap(find.byTooltip('Abrir filtros avançados'));
    await tester.pumpAndSettle();
    expect(find.text('Filtros avançados'), findsOneWidget);
    final dropdowns = find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField,
    );
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menor valor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Menor valor'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('Todo o período'), findsOneWidget);
    expect(find.text('Todas categorias'), findsOneWidget);
    expect(find.text('Mais recentes'), findsOneWidget);
    expect(find.text('3 gastos registrados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre a Dashboard financeira pelo menu inferior', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Visão geral das suas finanças'), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('Renda do mês'), findsOneWidget);
    expect(find.text('Total gasto'), findsOneWidget);
    expect(find.text('Saldo restante'), findsOneWidget);
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('Evolução dos gastos'), findsOneWidget);
    expect(find.text('Comparação com mês anterior'), findsOneWidget);
    expect(find.text('Maiores gastos do mês'), findsOneWidget);
    expect(find.text('Insight do mês'), findsOneWidget);
    expect(find.text('Uso da renda'), findsNothing);
    expect(find.text('Projeção do mês'), findsNothing);
    expect(find.text('Maior gasto'), findsNothing);
    expect(find.text('Evolução dos últimos 6 meses'), findsNothing);
    expect(find.text('Resumo anual'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard abre listas completas e alterna evolução', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        iconFontFamily:
            Icons.directions_car_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFFE3B53F,
        isDefault: true,
        createdAt: now,
      ),
    ];
    final expenses = FakeExpenseRepository()
      ..expenses.addAll([
        Expense(
          id: 1,
          amount: 300,
          categoryId: 'food',
          occurredAt: DateTime(now.year, now.month, 2),
          createdAt: now,
          updatedAt: now,
        ),
        Expense(
          id: 2,
          amount: 100,
          categoryId: 'transport',
          occurredAt: DateTime(now.year, now.month, 3),
          createdAt: now,
          updatedAt: now,
        ),
      ]);

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: categories,
        ),
        expenseRepository: expenses,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    expect(find.text('Todas as categorias'), findsOneWidget);
    expect(find.text('Alimentação'), findsWidgets);
    expect(find.text('75,0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ver ranking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver ranking'));
    await tester.pumpAndSettle();
    expect(find.text('Ranking por categoria'), findsOneWidget);
    expect(find.text('1º'), findsOneWidget);
    expect(find.text('2º'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthlyExpenseLineChart), findsOneWidget);
    await tester.ensureVisible(find.text('Diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensal').last);
    await tester.pumpAndSettle();
    expect(find.byType(MonthlyExpenseLineChart), findsNothing);
    expect(find.byType(SixMonthExpenseLineChart), findsOneWidget);
    expect(find.text('Mensal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard permanece responsiva em telas mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final categories = [
      ExpenseCategory(
        id: 'food',
        name: 'Alimentação e restaurantes favoritos',
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        iconFontFamily: Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFF1D1B4F,
        isDefault: true,
        createdAt: now,
      ),
      ExpenseCategory(
        id: 'transport',
        name: 'Transporte',
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        iconFontFamily:
            Icons.directions_car_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFFE3B53F,
        isDefault: true,
        createdAt: now,
      ),
      ExpenseCategory(
        id: 'subscriptions',
        name: 'Assinaturas',
        iconCodePoint: Icons.subscriptions_rounded.codePoint,
        iconFontFamily:
            Icons.subscriptions_rounded.fontFamily ?? 'MaterialIcons',
        colorValue: 0xFF4A7C59,
        isDefault: false,
        createdAt: now,
      ),
    ];
    final expenseRepository = FakeExpenseRepository();
    expenseRepository.expenses.addAll([
      Expense(
        id: 1,
        amount: 1890.45,
        categoryId: 'food',
        description: 'Mercado',
        occurredAt: DateTime(now.year, now.month, 1),
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: 2,
        amount: 987.65,
        categoryId: 'transport',
        description: 'Combustível',
        occurredAt: DateTime(now.year, now.month, 3),
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: 3,
        amount: 456.78,
        categoryId: 'subscriptions',
        description: 'Serviços digitais',
        occurredAt: DateTime(now.year, now.month, 5),
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    const mobileSizes = [Size(360, 800), Size(412, 915), Size(411, 923)];

    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(
        QuantoPossoApp(
          setupRepository: FakeSetupRepository(
            profile: UserProfile(
              id: 1,
              name: 'André',
              monthlyIncome: 123456.78,
              createdAt: now,
              updatedAt: now,
            ),
            categories: categories,
          ),
          expenseRepository: expenseRepository,
          preferencesRepository: FakeWidgetPreferencesRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Dashboard'));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();

      expect(find.text('Gastos por categoria'), findsOneWidget);
      expect(find.text('Evolução dos gastos'), findsOneWidget);
      expect(find.text('Comparação com mês anterior'), findsOneWidget);
      expect(find.text('Maiores gastos do mês'), findsOneWidget);
      expect(find.text('Insight do mês'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Falha no tamanho $size');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('abre Configurações e a edição do perfil', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final preferencesRepository = FakeWidgetPreferencesRepository();
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: preferencesRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsWidgets);
    expect(
      find.text('Personalize o aplicativo e gerencie seus dados.'),
      findsOneWidget,
    );
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('André'), findsOneWidget);
    expect(find.textContaining('Renda mensal:'), findsOneWidget);
    expect(find.textContaining('3.500,00'), findsOneWidget);
    expect(find.text('Tema do aplicativo'), findsOneWidget);
    expect(find.text('Categorias'), findsWidgets);
    expect(find.text('Recorrências'), findsOneWidget);
    expect(find.text('Assinaturas e compras parceladas'), findsOneWidget);
    expect(find.text('Dados e privacidade'), findsOneWidget);
    expect(find.text('Backup e dados'), findsOneWidget);
    expect(find.text('Seus dados ficam neste dispositivo'), findsOneWidget);
    expect(find.text('Quanto Posso'), findsOneWidget);
    expect(find.text('Versão 1.0.0'), findsOneWidget);
    expect(find.text('Sistema'), findsNothing);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);

    await tester.ensureVisible(find.text('Recorrências'));
    await tester.tap(find.text('Recorrências'));
    await tester.pumpAndSettle();
    expect(
      find.text('Gerencie suas assinaturas e compras parceladas.'),
      findsOneWidget,
    );
    expect(find.text('Nenhuma recorrência cadastrada.'), findsOneWidget);
    Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Escuro'));
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(preferencesRepository.mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(preferencesRepository.mode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );

    await tester.ensureVisible(find.text('André'));
    await tester.tap(find.text('André'));
    await tester.pumpAndSettle();

    expect(find.text('Editar perfil'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.elementAt(0).controller?.text, 'André');
    expect(fields.elementAt(1).controller?.text, '3.500,00');
  });

  testWidgets('Configurações permanecem responsivas em telas mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    final now = DateTime(2026);

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André da Silva com nome extenso',
            monthlyIncome: 123456.78,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentação',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();

    const mobileSizes = [Size(360, 800), Size(412, 915), Size(411, 923)];
    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();

      expect(find.text('Tema do aplicativo'), findsOneWidget);
      expect(find.text('Lembrete diário'), findsOneWidget);
      expect(find.text('Alerta de limite'), findsOneWidget);
      expect(find.text('Categorias'), findsOneWidget);
      expect(find.text('Backup e dados'), findsOneWidget);
      expect(find.text('Quanto Posso'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Falha no tamanho $size');
    }
  });

  testWidgets('abre o gerenciamento e o formulário de categorias', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final repository = FakeSetupRepository(
      profile: UserProfile(
        id: 1,
        name: 'André',
        monthlyIncome: 3500,
        createdAt: now,
        updatedAt: now,
      ),
      categories: [
        ExpenseCategory(
          id: 'food',
          name: 'Alimentação',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          iconFontFamily:
              Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
          colorValue: 0xFF1D1B4F,
          isDefault: true,
          createdAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: repository,
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    final categoriesItem = find.text('Categorias').last;
    await tester.ensureVisible(categoriesItem);
    await tester.tap(categoriesItem);
    await tester.pumpAndSettle();

    expect(find.text('Categorias'), findsOneWidget);
    await tester.tap(find.byTooltip('Nova categoria'));
    await tester.pumpAndSettle();

    expect(find.text('Nova categoria'), findsOneWidget);
    expect(find.text('Nome da categoria'), findsOneWidget);
    expect(find.text('Escolha um ícone'), findsOneWidget);
    expect(find.text('Escolha uma cor'), findsOneWidget);
    expect(find.text('Criar categoria'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Assinaturas');
    final createButton = find.text('Criar categoria');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Categoria criada com sucesso.'), findsOneWidget);
    expect(find.text('Assinaturas'), findsOneWidget);
    expect(
      repository.savedCategories.where(
        (category) => category.name == 'Assinaturas',
      ),
      hasLength(1),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar gasto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    expect(find.text('Assinaturas'), findsOneWidget);
  });

  testWidgets('exibe as configurações do lembrete diário', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026);
    final preferencesRepository = FakeWidgetPreferencesRepository();
    final notificationProvider = NotificationProvider(
      preferencesRepository: preferencesRepository,
      notificationService: FakeWidgetNotificationScheduler(),
    );
    await notificationProvider.initialize();
    final budgetScheduler = FakeWidgetNotificationScheduler()
      ..permissionGranted = true;
    final budgetAlertProvider = BudgetAlertProvider(
      preferencesRepository: preferencesRepository,
      notificationService: budgetScheduler,
    );
    await budgetAlertProvider.initialize();

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentação',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: FakeExpenseRepository(),
        preferencesRepository: preferencesRepository,
        notificationProvider: notificationProvider,
        budgetAlertProvider: budgetAlertProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Recorrências'), findsOneWidget);
    expect(find.text('Assinaturas e compras parceladas'), findsOneWidget);
    expect(find.text('Lembrete diário'), findsOneWidget);
    expect(find.text('Testar notificação'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);

    final budgetCard = find.byType(BudgetAlertSettingsCard);
    await tester.ensureVisible(budgetCard);
    expect(find.text('Alerta de limite'), findsOneWidget);

    await tester.tap(
      find.descendant(of: budgetCard, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    expect(find.text('70%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    await tester.tap(find.text('90%'));
    await tester.pumpAndSettle();
    expect(budgetAlertProvider.preferences.thresholdPercentage, 90);
  });

  testWidgets('exclui gasto pelo botão de lixeira após confirmação', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final expenseRepository = FakeExpenseRepository()
      ..expenses.add(
        Expense(
          id: 1,
          amount: 45,
          categoryId: 'food',
          description: 'Gasto excluível',
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
    final preferencesRepository = FakeWidgetPreferencesRepository();
    final budgetAlertProvider = BudgetAlertProvider(
      preferencesRepository: preferencesRepository,
      notificationService: FakeWidgetNotificationScheduler()
        ..permissionGranted = true,
    );
    await budgetAlertProvider.initialize();

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentação',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: expenseRepository,
        preferencesRepository: preferencesRepository,
        budgetAlertProvider: budgetAlertProvider,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Excluir gasto'), findsOneWidget);
    await tester.tap(find.byTooltip('Excluir gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir gasto?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Gasto excluível'), findsNothing);
    expect(find.text('Gasto excluído com sucesso.'), findsOneWidget);
    expect(expenseRepository.expenses, isEmpty);
  });

  testWidgets('arrastar gasto não inicia exclusão', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final expenseRepository = FakeExpenseRepository()
      ..expenses.add(
        Expense(
          id: 1,
          amount: 45,
          categoryId: 'food',
          description: 'Gasto mantido',
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
    final preferencesRepository = FakeWidgetPreferencesRepository();
    final budgetAlertProvider = BudgetAlertProvider(
      preferencesRepository: preferencesRepository,
      notificationService: FakeWidgetNotificationScheduler()
        ..permissionGranted = true,
    );
    await budgetAlertProvider.initialize();

    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'André',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentação',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: expenseRepository,
        preferencesRepository: preferencesRepository,
        budgetAlertProvider: budgetAlertProvider,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Gasto mantido'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('Excluir gasto?'), findsNothing);
    expect(find.text('Gasto mantido'), findsOneWidget);
    expect(expenseRepository.expenses, hasLength(1));
  });

  testWidgets('edita gasto existente pelo Historico', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final expenseRepository = FakeExpenseRepository()
      ..expenses.add(
        Expense(
          id: 1,
          amount: 45,
          categoryId: 'food',
          description: 'Descricao antiga',
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
    await tester.pumpWidget(
      QuantoPossoApp(
        setupRepository: FakeSetupRepository(
          profile: UserProfile(
            id: 1,
            name: 'Andre',
            monthlyIncome: 3500,
            createdAt: now,
            updatedAt: now,
          ),
          categories: [
            ExpenseCategory(
              id: 'food',
              name: 'Alimentacao',
              iconCodePoint: Icons.restaurant_rounded.codePoint,
              iconFontFamily:
                  Icons.restaurant_rounded.fontFamily ?? 'MaterialIcons',
              colorValue: 0xFF1D1B4F,
              isDefault: true,
              createdAt: now,
            ),
          ],
        ),
        expenseRepository: expenseRepository,
        preferencesRepository: FakeWidgetPreferencesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto'), findsOneWidget);
    expect(find.text('Atualize o lançamento'), findsOneWidget);
    expect(find.text('Valor do gasto'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Descri\u00e7\u00e3o opcional'), findsOneWidget);
    expect(find.text('Salvar altera\u00e7\u00f5es'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.last, 'Descricao atualizada');
    final saveButton = find.text('Salvar altera\u00e7\u00f5es');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Gasto atualizado com sucesso.'), findsOneWidget);
    expect(find.text('Descricao atualizada'), findsOneWidget);
    expect(expenseRepository.expenses, hasLength(1));
    expect(expenseRepository.expenses.single.id, 1);
  });
}
