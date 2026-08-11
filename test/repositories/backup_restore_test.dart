import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/app_backup.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePickerService implements BackupPickerService {
  FakePickerService(this.file);

  final PickedBackupFile? file;

  @override
  Future<PickedBackupFile?> pickBackupFile() async => file;
}

class FakeDatabaseRestoreService implements BackupDatabaseRestoreService {
  bool called = false;
  Object? error;

  @override
  Future<void> restore(AppBackup backup) async {
    called = true;
    if (error case final error?) throw error;
  }
}

class FakeImportPreferencesRepository extends PreferencesRepository {
  bool imported = false;

  @override
  Future<void> importPreferences(Map<String, Object?> preferences) async {
    imported = true;
  }
}

AppBackup validBackup({
  int version = 1,
  String appName = 'Quanto Posso',
  Map<String, Object?>? profile,
  List<Map<String, Object?>>? categories,
  List<Map<String, Object?>>? expenses,
  List<Map<String, Object?>> recurringPlans = const [],
  Map<String, Object?> preferences = const {},
}) {
  final date = DateTime.utc(2026, 8, 5, 9, 15).toIso8601String();
  return AppBackup(
    backupVersion: version,
    appName: appName,
    exportedAt: DateTime.parse(date),
    profile:
        profile ??
        {
          'id': 1,
          'name': 'Andr\u00e9',
          'monthly_income': 3500.0,
          'created_at': date,
          'updated_at': date,
        },
    categories:
        categories ??
        [
          {
            'id': 'food',
            'name': 'Alimenta\u00e7\u00e3o',
            'icon_code_point': 1,
            'icon_font_family': 'MaterialIcons',
            'color_value': 1,
            'is_default': 1,
            'created_at': date,
          },
        ],
    expenses:
        expenses ??
        [
          {
            'id': 1,
            'amount': 25.0,
            'category_id': 'food',
            'description': 'Almo\u00e7o',
            'occurred_at': date,
            'created_at': date,
            'updated_at': date,
          },
        ],
    recurringPlans: recurringPlans,
    preferences: preferences,
  );
}

BackupRepository repositoryFor(AppBackup backup) {
  return BackupRepository(
    pickerService: FakePickerService(
      PickedBackupFile(name: 'backup.json', content: jsonEncode(backup)),
    ),
  );
}

void main() {
  test('JSON v\u00e1lido gera preview', () async {
    final preview = await repositoryFor(
      validBackup(),
    ).selectAndValidateBackup();
    expect(preview?.profileName, 'Andr\u00e9');
    expect(preview?.categoryCount, 1);
    expect(preview?.expenseCount, 1);
  });

  test('cancelamento retorna null', () async {
    final repository = BackupRepository(pickerService: FakePickerService(null));
    expect(await repository.selectAndValidateBackup(), isNull);
  });

  test('arquivo maior que 10 MB \u00e9 rejeitado', () async {
    final repository = BackupRepository(
      pickerService: FakePickerService(
        PickedBackupFile(
          name: 'backup.json',
          content: 'a' * (10 * 1024 * 1024 + 1),
        ),
      ),
    );
    expect(
      repository.selectAndValidateBackup(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'O arquivo de backup \u00e9 muito grande.',
        ),
      ),
    );
  });

  test('app_name inv\u00e1lido \u00e9 rejeitado', () {
    expect(
      repositoryFor(validBackup(appName: 'Outro')).selectAndValidateBackup(),
      throwsFormatException,
    );
  });

  test('vers\u00e3o inv\u00e1lida \u00e9 rejeitada', () {
    expect(
      repositoryFor(validBackup(version: 4)).selectAndValidateBackup(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Vers\u00e3o de backup n\u00e3o suportada.',
        ),
      ),
    );
  });

  test('perfil inv\u00e1lido \u00e9 rejeitado', () {
    expect(
      repositoryFor(validBackup(profile: const {})).selectAndValidateBackup(),
      throwsFormatException,
    );
  });

  test('categoria duplicada \u00e9 rejeitada', () {
    final category = validBackup().categories.first;
    expect(
      repositoryFor(
        validBackup(categories: [category, Map.of(category)]),
      ).selectAndValidateBackup(),
      throwsFormatException,
    );
  });

  test('gasto com categoria inexistente \u00e9 rejeitado', () {
    final expense = Map<String, Object?>.from(validBackup().expenses.first)
      ..['category_id'] = 'missing';
    expect(
      repositoryFor(validBackup(expenses: [expense])).selectAndValidateBackup(),
      throwsFormatException,
    );
  });

  test('backup v2 preserva plano e lancamento recorrente', () async {
    final date = DateTime.utc(2026, 8, 5, 9, 15).toIso8601String();
    final plan = {
      'id': 8,
      'type': 'installment',
      'category_id': 'food',
      'description': 'Notebook',
      'amount': 3000.0,
      'start_date': date,
      'billing_day': 5,
      'total_occurrences': 10,
      'generated_occurrences': 1,
      'is_active': 1,
      'created_at': date,
      'updated_at': date,
    };
    final expense = Map<String, Object?>.from(validBackup().expenses.first)
      ..addAll({
        'recurring_plan_id': 8,
        'occurrence_number': 1,
        'occurrence_total': 10,
        'recurring_type': 'installment',
      });
    final preview = await repositoryFor(
      validBackup(version: 2, recurringPlans: [plan], expenses: [expense]),
    ).selectAndValidateBackup();
    expect(preview?.backup.recurringPlans, hasLength(1));
    expect(preview?.backup.expenses.single['recurring_plan_id'], 8);
  });

  test('backup v3 preserva status cancelado', () async {
    final date = DateTime.utc(2026, 8, 5, 9, 15).toIso8601String();
    final plan = {
      'id': 8,
      'type': 'subscription',
      'category_id': 'food',
      'description': 'Streaming',
      'amount': 49.9,
      'start_date': date,
      'billing_day': 5,
      'total_occurrences': null,
      'generated_occurrences': 4,
      'is_active': 0,
      'status': 'cancelled',
      'created_at': date,
      'updated_at': date,
    };
    final preview = await repositoryFor(
      validBackup(version: 3, recurringPlans: [plan]),
    ).selectAndValidateBackup();
    expect(preview?.backup.recurringPlans.single['status'], 'cancelled');
  });

  test('gasto recorrente sem plano correspondente \u00e9 rejeitado', () {
    final expense = Map<String, Object?>.from(validBackup().expenses.first)
      ..addAll({
        'recurring_plan_id': 99,
        'occurrence_number': 1,
        'occurrence_total': null,
        'recurring_type': 'subscription',
      });
    expect(
      repositoryFor(
        validBackup(version: 2, expenses: [expense]),
      ).selectAndValidateBackup(),
      throwsFormatException,
    );
  });

  test('restaura\u00e7\u00e3o segue a ordem transacional obrigat\u00f3ria', () {
    expect(LocalBackupDatabaseRestoreService.operationOrder, [
      'delete expenses',
      'delete recurring plans',
      'delete categories',
      'delete profiles',
      'insert profile',
      'insert categories',
      'insert recurring plans',
      'insert expenses',
    ]);
  });

  test(
    'falha na opera\u00e7\u00e3o at\u00f4mica n\u00e3o importa prefer\u00eancias',
    () async {
      // O rollback concreto pertence ao transaction do sqflite. Sem adicionar
      // sqflite_common_ffi, este teste verifica a fronteira at\u00f4mica injetada.
      final database = FakeDatabaseRestoreService()
        ..error = StateError('insert failed');
      final preferences = FakeImportPreferencesRepository();
      final repository = BackupRepository(
        databaseRestoreService: database,
        preferencesRepository: preferences,
      );
      await expectLater(
        repository.restoreBackup(validBackup()),
        throwsStateError,
      );
      expect(database.called, isTrue);
      expect(preferences.imported, isFalse);
    },
  );

  test('prefer\u00eancias desconhecidas s\u00e3o ignoradas', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PreferencesRepository();
    await repository.importPreferences(const {'plugin_secret': 'ignore'});
    expect(await repository.exportPreferences(), isEmpty);
  });

  test(
    'prefer\u00eancia conhecida com tipo inv\u00e1lido \u00e9 rejeitada',
    () {
      final repository = PreferencesRepository();
      expect(
        repository.importPreferences(const {'daily_reminder_hour': '20'}),
        throwsFormatException,
      );
    },
  );
}
