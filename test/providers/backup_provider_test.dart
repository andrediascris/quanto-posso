import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/app_backup.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';
import 'package:quanto_posso/providers/backup_provider.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';

class FakeBackupRepository extends BackupRepository {
  FakeBackupRepository({
    this.result,
    this.error,
    this.completer,
    this.preview,
    this.selectError,
    this.selectCompleter,
    this.restoreError,
  });

  final BackupExportResult? result;
  final Object? error;
  final Completer<BackupExportResult>? completer;
  final BackupImportPreview? preview;
  final Object? selectError;
  final Completer<BackupImportPreview?>? selectCompleter;
  final Object? restoreError;
  int calls = 0;
  int selectCalls = 0;
  int restoreCalls = 0;

  @override
  Future<BackupExportResult> exportAndShareBackup() async {
    calls++;
    if (error case final error?) throw error;
    if (completer case final completer?) return completer.future;
    return result!;
  }

  @override
  Future<BackupImportPreview?> selectAndValidateBackup() async {
    selectCalls++;
    if (selectError case final error?) throw error;
    if (selectCompleter case final completer?) return completer.future;
    return preview;
  }

  @override
  Future<void> restoreBackup(AppBackup backup) async {
    restoreCalls++;
    if (restoreError case final error?) throw error;
  }
}

void main() {
  final result = BackupExportResult(
    fileName: 'quanto_posso_backup_2026-08-05_0915.json',
    filePath: 'temporary/backup.json',
    exportedAt: DateTime(2026, 8, 5, 9, 15),
    categoryCount: 2,
    expenseCount: 3,
  );
  final backup = AppBackup(
    backupVersion: 1,
    appName: 'Quanto Posso',
    exportedAt: DateTime(2026, 8, 5),
    profile: const {'name': 'Andr\u00e9'},
    categories: const [],
    expenses: const [],
    preferences: const {},
  );
  late BackupImportPreview preview;

  setUp(() {
    preview = BackupImportPreview(
      backup: backup,
      fileName: 'backup.json',
      categoryCount: 1,
      expenseCount: 2,
      profileName: 'Andr\u00e9',
      monthlyIncome: 3500,
      exportedAt: backup.exportedAt,
    );
  });

  test('estado inicial', () {
    final provider = BackupProvider(repository: FakeBackupRepository());
    expect(provider.status, BackupStatus.initial);
    expect(provider.lastExport, isNull);
    expect(provider.errorMessage, isNull);
    expect(provider.isExporting, isFalse);
  });

  test('exporta\u00e7\u00e3o entra em exporting', () async {
    final completer = Completer<BackupExportResult>();
    final provider = BackupProvider(
      repository: FakeBackupRepository(completer: completer),
    );
    final future = provider.exportBackup();
    expect(provider.status, BackupStatus.exporting);
    completer.complete(result);
    await future;
  });

  test('sucesso guarda resultado e retorna true', () async {
    final provider = BackupProvider(
      repository: FakeBackupRepository(result: result),
    );
    expect(await provider.exportBackup(), isTrue);
    expect(provider.status, BackupStatus.success);
    expect(provider.lastExport, same(result));
    expect(provider.errorMessage, isNull);
  });

  test('erro define status error e retorna false', () async {
    final provider = BackupProvider(
      repository: FakeBackupRepository(error: StateError('falha')),
    );
    expect(await provider.exportBackup(), isFalse);
    expect(provider.status, BackupStatus.error);
    expect(provider.errorMessage, 'N\u00e3o foi poss\u00edvel criar o backup.');
  });

  test(
    'segunda exporta\u00e7\u00e3o simult\u00e2nea n\u00e3o executa novamente',
    () async {
      final completer = Completer<BackupExportResult>();
      final repository = FakeBackupRepository(completer: completer);
      final provider = BackupProvider(repository: repository);
      final first = provider.exportBackup();
      expect(await provider.exportBackup(), isFalse);
      expect(repository.calls, 1);
      completer.complete(result);
      expect(await first, isTrue);
    },
  );

  test('selecionar arquivo v\u00e1lido gera previewReady', () async {
    final provider = BackupProvider(
      repository: FakeBackupRepository(preview: preview),
    );
    expect(await provider.selectBackup(), same(preview));
    expect(provider.status, BackupStatus.previewReady);
    expect(provider.importPreview, same(preview));
  });

  test('cancelar sele\u00e7\u00e3o n\u00e3o gera erro', () async {
    final provider = BackupProvider(repository: FakeBackupRepository());
    expect(await provider.selectBackup(), isNull);
    expect(provider.status, BackupStatus.initial);
    expect(provider.errorMessage, isNull);
  });

  test('arquivo inv\u00e1lido gera restoreError', () async {
    final provider = BackupProvider(
      repository: FakeBackupRepository(
        selectError: const FormatException('Arquivo de backup inv\u00e1lido.'),
      ),
    );
    expect(await provider.selectBackup(), isNull);
    expect(provider.status, BackupStatus.restoreError);
    expect(provider.errorMessage, 'Arquivo de backup inv\u00e1lido.');
  });

  test('restaurar backup v\u00e1lido gera restoreSuccess', () async {
    final repository = FakeBackupRepository(preview: preview);
    final provider = BackupProvider(repository: repository);
    await provider.selectBackup();
    expect(await provider.restoreSelectedBackup(), isTrue);
    expect(provider.status, BackupStatus.restoreSuccess);
    expect(provider.importPreview, isNull);
    expect(repository.restoreCalls, 1);
  });

  test('erro ao restaurar gera restoreError', () async {
    final provider = BackupProvider(
      repository: FakeBackupRepository(
        preview: preview,
        restoreError: StateError('failure'),
      ),
    );
    await provider.selectBackup();
    expect(await provider.restoreSelectedBackup(), isFalse);
    expect(provider.status, BackupStatus.restoreError);
  });

  test(
    'restaura\u00e7\u00e3o parcial retorna sucesso com flag parcial',
    () async {
      final provider = BackupProvider(
        repository: FakeBackupRepository(
          preview: preview,
          restoreError: const PartialBackupRestoreException(),
        ),
      );
      await provider.selectBackup();
      expect(await provider.restoreSelectedBackup(), isTrue);
      expect(provider.status, BackupStatus.restoreSuccess);
      expect(provider.wasPartialRestore, isTrue);
    },
  );

  test(
    'chamadas simult\u00e2neas de sele\u00e7\u00e3o s\u00e3o bloqueadas',
    () async {
      final completer = Completer<BackupImportPreview?>();
      final repository = FakeBackupRepository(selectCompleter: completer);
      final provider = BackupProvider(repository: repository);
      final first = provider.selectBackup();
      expect(provider.isSelecting, isTrue);
      expect(await provider.selectBackup(), isNull);
      expect(repository.selectCalls, 1);
      completer.complete(preview);
      expect(await first, same(preview));
    },
  );
}
