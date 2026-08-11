import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quanto_posso/core/database/app_database.dart';
import 'package:quanto_posso/models/app_backup.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class BackupFileService {
  Future<String> writeTemporaryBackup({
    required String fileName,
    required String content,
  });

  Future<void> shareBackup({
    required String filePath,
    required String fileName,
  });
}

abstract interface class BackupPickerService {
  Future<PickedBackupFile?> pickBackupFile();
}

class PickedBackupFile {
  const PickedBackupFile({required this.name, required this.content});

  final String name;
  final String content;
}

class LocalBackupPickerService implements BackupPickerService {
  static const _maximumBytes = 10 * 1024 * 1024;

  @override
  Future<PickedBackupFile?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > _maximumBytes) {
      throw const FormatException('O arquivo de backup \u00e9 muito grande.');
    }
    final bytes = file.bytes;
    if (bytes != null) {
      return PickedBackupFile(name: file.name, content: utf8.decode(bytes));
    }
    final path = file.path;
    if (path == null) {
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
    final source = File(path);
    if (await source.length() > _maximumBytes) {
      throw const FormatException('O arquivo de backup \u00e9 muito grande.');
    }
    return PickedBackupFile(
      name: file.name,
      content: await source.readAsString(encoding: utf8),
    );
  }
}

abstract interface class BackupDatabaseRestoreService {
  Future<void> restore(AppBackup backup);
}

class LocalBackupDatabaseRestoreService
    implements BackupDatabaseRestoreService {
  LocalBackupDatabaseRestoreService({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const operationOrder = [
    'delete expenses',
    'delete recurring plans',
    'delete categories',
    'delete profiles',
    'insert profile',
    'insert categories',
    'insert recurring plans',
    'insert expenses',
  ];

  @override
  Future<void> restore(AppBackup backup) async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete('expenses');
      await transaction.delete('recurring_expense_plans');
      await transaction.delete('categories');
      await transaction.delete('profiles');

      final profileMap = Map<String, Object?>.from(backup.profile!)..['id'] = 1;
      final profile = UserProfile.fromMap(profileMap);
      await transaction.insert('profiles', profile.toMap());

      final categoryBatch = transaction.batch();
      for (final map in backup.categories) {
        categoryBatch.insert(
          'categories',
          ExpenseCategory.fromMap(map).toMap(),
        );
      }
      await categoryBatch.commit(noResult: true);

      final planBatch = transaction.batch();
      for (final map in backup.recurringPlans) {
        planBatch.insert(
          'recurring_expense_plans',
          RecurringExpensePlan.fromMap(map).toMap(),
        );
      }
      await planBatch.commit(noResult: true);

      final expenseBatch = transaction.batch();
      for (final map in backup.expenses) {
        expenseBatch.insert('expenses', Expense.fromMap(map).toMap());
      }
      await expenseBatch.commit(noResult: true);
    });
  }
}

class PartialBackupRestoreException implements Exception {
  const PartialBackupRestoreException();

  String get message =>
      'Os dados foram restaurados, mas algumas prefer\u00eancias n\u00e3o puderam ser aplicadas.';

  @override
  String toString() => message;
}

class LocalBackupFileService implements BackupFileService {
  @override
  Future<String> writeTemporaryBackup({
    required String fileName,
    required String content,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  @override
  Future<void> shareBackup({
    required String filePath,
    required String fileName,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json', name: fileName)],
        fileNameOverrides: [fileName],
        subject: 'Backup do Quanto Posso',
        text: 'Backup dos meus dados do Quanto Posso.',
      ),
    );
  }
}

class BackupExportResult {
  const BackupExportResult({
    required this.fileName,
    required this.filePath,
    required this.exportedAt,
    required this.categoryCount,
    required this.expenseCount,
  });

  final String fileName;
  final String filePath;
  final DateTime exportedAt;
  final int categoryCount;
  final int expenseCount;
}

class BackupRepository {
  BackupRepository({
    SetupRepository? setupRepository,
    ExpenseRepository? expenseRepository,
    PreferencesRepository? preferencesRepository,
    BackupFileService? fileService,
    BackupPickerService? pickerService,
    BackupDatabaseRestoreService? databaseRestoreService,
    RecurringExpenseRepository? recurringExpenseRepository,
  }) : _setupRepository = setupRepository ?? SetupRepository(),
       _expenseRepository = expenseRepository ?? ExpenseRepository(),
       _preferencesRepository =
           preferencesRepository ?? PreferencesRepository(),
       _fileService = fileService ?? LocalBackupFileService(),
       _pickerService = pickerService ?? LocalBackupPickerService(),
       _databaseRestoreService =
           databaseRestoreService ?? LocalBackupDatabaseRestoreService(),
       _recurringExpenseRepository =
           recurringExpenseRepository ??
           (expenseRepository == null ? RecurringExpenseRepository() : null);

  final SetupRepository _setupRepository;
  final ExpenseRepository _expenseRepository;
  final PreferencesRepository _preferencesRepository;
  final BackupFileService _fileService;
  final BackupPickerService _pickerService;
  final BackupDatabaseRestoreService _databaseRestoreService;
  final RecurringExpenseRepository? _recurringExpenseRepository;

  static const _maximumBackupBytes = 10 * 1024 * 1024;

  Future<AppBackup> createBackup() async {
    final profile = await _setupRepository.getProfile();
    if (profile == null) {
      throw StateError('N\u00e3o existe perfil configurado para exportar.');
    }
    final categories = await _setupRepository.getCategories();
    final expenses = await _expenseRepository.getAllExpenses();
    final preferences = await _preferencesRepository.exportPreferences();
    final recurringPlans =
        await _recurringExpenseRepository?.getPlans() ?? const [];

    return AppBackup(
      backupVersion: 3,
      appName: 'Quanto Posso',
      exportedAt: DateTime.now(),
      profile: profile.toMap(),
      categories: categories
          .map((item) => item.toMap())
          .toList(growable: false),
      expenses: expenses.map((item) => item.toMap()).toList(growable: false),
      preferences: preferences,
      recurringPlans: recurringPlans
          .map((plan) => plan.toMap())
          .toList(growable: false),
    );
  }

  String encodeBackup(AppBackup backup) =>
      const JsonEncoder.withIndent('  ').convert(backup.toJson());

  Future<BackupExportResult> exportAndShareBackup() async {
    final backup = await createBackup();
    final fileName =
        'quanto_posso_backup_${DateFormat('yyyy-MM-dd_HHmm').format(backup.exportedAt)}.json';
    final filePath = await _fileService.writeTemporaryBackup(
      fileName: fileName,
      content: encodeBackup(backup),
    );
    await _fileService.shareBackup(filePath: filePath, fileName: fileName);
    return BackupExportResult(
      fileName: fileName,
      filePath: filePath,
      exportedAt: backup.exportedAt,
      categoryCount: backup.categories.length,
      expenseCount: backup.expenses.length,
    );
  }

  Future<BackupImportPreview?> selectAndValidateBackup() async {
    final PickedBackupFile? selected;
    try {
      selected = await _pickerService.pickBackupFile();
    } on FormatException catch (error) {
      if (error.message == 'O arquivo de backup \u00e9 muito grande.') {
        rethrow;
      }
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
    if (selected == null) return null;
    if (utf8.encode(selected.content).length > _maximumBackupBytes) {
      throw const FormatException('O arquivo de backup \u00e9 muito grande.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(selected.content);
    } on FormatException {
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
    final root = _asStringMap(decoded);
    final AppBackup backup;
    try {
      backup = AppBackup.fromJson(root);
    } on FormatException catch (error) {
      if (error.message.toString().contains('app_name')) {
        throw const FormatException(
          'O arquivo n\u00e3o pertence ao Quanto Posso.',
        );
      }
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
    _validateBackup(backup);
    final profile = UserProfile.fromMap(backup.profile!);
    return BackupImportPreview(
      backup: backup,
      fileName: selected.name,
      categoryCount: backup.categories.length,
      expenseCount: backup.expenses.length,
      profileName: profile.name,
      monthlyIncome: profile.monthlyIncome,
      exportedAt: backup.exportedAt,
    );
  }

  Future<void> restoreBackup(AppBackup backup) async {
    _validateBackup(backup);
    await _databaseRestoreService.restore(backup);
    try {
      await _preferencesRepository.importPreferences(backup.preferences);
    } on Object {
      throw const PartialBackupRestoreException();
    }
  }

  Map<String, Object?> _asStringMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException('Arquivo de backup inv\u00e1lido.');
      }
      result[key] = entry.value;
    }
    return result;
  }

  void _validateBackup(AppBackup backup) {
    if (backup.backupVersion < 1 || backup.backupVersion > 3) {
      throw const FormatException('Vers\u00e3o de backup n\u00e3o suportada.');
    }
    if (backup.appName != 'Quanto Posso') {
      throw const FormatException(
        'O arquivo n\u00e3o pertence ao Quanto Posso.',
      );
    }
    final profile = backup.profile;
    if (profile == null || !_isValidProfile(profile)) {
      throw const FormatException(
        'O backup n\u00e3o possui um perfil v\u00e1lido.',
      );
    }
    if (!_hasValidCategories(backup.categories)) {
      throw const FormatException(
        'O backup n\u00e3o possui categorias v\u00e1lidas.',
      );
    }
    if (!_hasValidExpenses(
      backup.expenses,
      backup.categories,
      backup.recurringPlans,
    )) {
      throw const FormatException('O backup possui gastos inv\u00e1lidos.');
    }
    if (!_hasValidRecurringPlans(backup.recurringPlans, backup.categories)) {
      throw const FormatException('O backup possui recorrências inválidas.');
    }
    try {
      _preferencesRepository.validateImportPreferences(backup.preferences);
    } on FormatException {
      throw const FormatException('Arquivo de backup inv\u00e1lido.');
    }
  }

  bool _isValidProfile(Map<String, Object?> profile) {
    final id = profile['id'];
    final name = profile['name'];
    final income = profile['monthly_income'];
    return id is int &&
        name is String &&
        name.trim().length >= 2 &&
        income is num &&
        income > 0 &&
        _isDate(profile['created_at']) &&
        _isDate(profile['updated_at']);
  }

  bool _hasValidCategories(List<Map<String, Object?>> categories) {
    if (categories.isEmpty) return false;
    final ids = <String>{};
    for (final category in categories) {
      final id = category['id'];
      final name = category['name'];
      final isDefault = category['is_default'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          name is! String ||
          name.trim().isEmpty ||
          category['icon_code_point'] is! int ||
          category['icon_font_family'] is! String ||
          category['color_value'] is! int ||
          isDefault is! int ||
          (isDefault != 0 && isDefault != 1) ||
          !_isDate(category['created_at'])) {
        return false;
      }
    }
    return true;
  }

  bool _hasValidExpenses(
    List<Map<String, Object?>> expenses,
    List<Map<String, Object?>> categories,
    List<Map<String, Object?>> plans,
  ) {
    final categoryIds = categories.map((item) => item['id']).toSet();
    final planIds = plans.map((item) => item['id']).toSet();
    final expenseIds = <int>{};
    final occurrences = <String>{};
    for (final expense in expenses) {
      final id = expense['id'];
      final amount = expense['amount'];
      final recurringPlanId = expense['recurring_plan_id'];
      final occurrenceNumber = expense['occurrence_number'];
      final occurrenceTotal = expense['occurrence_total'];
      final recurringType = expense['recurring_type'];
      final occurrenceKey = recurringPlanId == null
          ? null
          : '$recurringPlanId:$occurrenceNumber';
      if ((id != null && (id is! int || !expenseIds.add(id))) ||
          amount is! num ||
          amount <= 0 ||
          !categoryIds.contains(expense['category_id']) ||
          (expense['description'] != null &&
              expense['description'] is! String) ||
          !_isDate(expense['occurred_at']) ||
          !_isDate(expense['created_at']) ||
          !_isDate(expense['updated_at']) ||
          (recurringPlanId == null &&
              (occurrenceNumber != null ||
                  occurrenceTotal != null ||
                  recurringType != null)) ||
          (recurringPlanId != null &&
              (recurringPlanId is! int ||
                  !planIds.contains(recurringPlanId) ||
                  occurrenceNumber is! int ||
                  occurrenceNumber <= 0 ||
                  (occurrenceTotal != null &&
                      (occurrenceTotal is! int || occurrenceTotal <= 0)) ||
                  (recurringType != 'subscription' &&
                      recurringType != 'installment') ||
                  !occurrences.add(occurrenceKey!)))) {
        return false;
      }
    }
    return true;
  }

  bool _hasValidRecurringPlans(
    List<Map<String, Object?>> plans,
    List<Map<String, Object?>> categories,
  ) {
    final categoryIds = categories.map((item) => item['id']).toSet();
    final ids = <int>{};
    for (final plan in plans) {
      final id = plan['id'];
      final type = plan['type'];
      final total = plan['total_occurrences'];
      final generated = plan['generated_occurrences'];
      final isActive = plan['is_active'];
      final status = plan['status'];
      if (id is! int ||
          !ids.add(id) ||
          (type != 'subscription' && type != 'installment') ||
          !categoryIds.contains(plan['category_id']) ||
          (plan['description'] != null && plan['description'] is! String) ||
          plan['amount'] is! num ||
          (plan['amount'] as num) <= 0 ||
          plan['billing_day'] is! int ||
          (plan['billing_day'] as int) < 1 ||
          (plan['billing_day'] as int) > 31 ||
          (total != null && (total is! int || total <= 0)) ||
          generated is! int ||
          generated < 0 ||
          isActive is! int ||
          (isActive != 0 && isActive != 1) ||
          (status != null &&
              status != 'active' &&
              status != 'completed' &&
              status != 'cancelled') ||
          (status == 'active' && isActive != 1) ||
          ((status == 'completed' || status == 'cancelled') && isActive != 0) ||
          !_isDate(plan['start_date']) ||
          !_isDate(plan['created_at']) ||
          !_isDate(plan['updated_at'])) {
        return false;
      }
    }
    return true;
  }

  bool _isDate(Object? value) =>
      value is String && DateTime.tryParse(value) != null;
}
