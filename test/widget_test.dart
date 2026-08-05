import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/app/app.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/daily_expense_total.dart';
import 'package:quanto_posso/models/expense_category.dart';
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
    return const {};
  }

  @override
  Future<List<DailyExpenseTotal>> getDailyTotalsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    return const [];
  }
}

class FakeWidgetPreferencesRepository extends PreferencesRepository {
  ThemeMode mode = ThemeMode.system;
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
    mode = ThemeMode.system;
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

    await tester.tap(find.text('Configura\u00e7\u00f5es'));
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

    expect(find.text('Saiba quanto você ainda pode gastar.'), findsOneWidget);

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'André');
    await tester.enterText(fields.at(1), '3500');

    final continueButton = find.text('Continuar');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Escolha suas categorias'), findsOneWidget);

    await tester.tap(find.text('Finalizar configuração'));
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
    expect(find.text('Saiba quanto você ainda pode gastar.'), findsNothing);
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

    expect(find.text('Novo gasto'), findsOneWidget);
    expect(find.text('Valor'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Descrição opcional'), findsOneWidget);
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

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Histórico'), findsWidgets);
    expect(find.text('Pesquisar'), findsOneWidget);
    expect(find.text('Todas as categorias'), findsOneWidget);
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

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total gasto'), findsOneWidget);
    expect(find.text('Saldo restante'), findsOneWidget);
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('Evolução no mês'), findsOneWidget);
  });

  testWidgets('abre Configurações e a edição do perfil', (
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

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsWidgets);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Categorias'), findsWidgets);
    expect(find.text('Privacidade'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);

    await tester.tap(find.text('André'));
    await tester.pumpAndSettle();

    expect(find.text('Editar perfil'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.elementAt(0).controller?.text, 'André');
    expect(fields.elementAt(1).controller?.text, '3.500,00');
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

    await tester.tap(find.text('Configurações'));
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
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar gasto'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
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

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
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
    await tester.tap(find.text('Histórico'));
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

  testWidgets('cancelar exclusão por swipe mantém o gasto', (
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
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Gasto mantido'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Excluir gasto?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Hist\u00f3rico'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto'), findsOneWidget);
    expect(find.text('Valor'), findsOneWidget);
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
