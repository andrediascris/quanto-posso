import 'package:flutter/foundation.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';

enum BackupStatus {
  initial,
  exporting,
  success,
  error,
  selecting,
  previewReady,
  restoring,
  restoreSuccess,
  restoreError,
}

class BackupProvider extends ChangeNotifier {
  BackupProvider({BackupRepository? repository})
    : _repository = repository ?? BackupRepository();

  final BackupRepository _repository;
  BackupStatus _status = BackupStatus.initial;
  BackupExportResult? _lastExport;
  String? _errorMessage;
  BackupImportPreview? _importPreview;
  bool _wasPartialRestore = false;

  BackupStatus get status => _status;
  BackupExportResult? get lastExport => _lastExport;
  String? get errorMessage => _errorMessage;
  bool get isExporting => _status == BackupStatus.exporting;
  BackupImportPreview? get importPreview => _importPreview;
  bool get wasPartialRestore => _wasPartialRestore;
  bool get isSelecting => _status == BackupStatus.selecting;
  bool get isRestoring => _status == BackupStatus.restoring;

  bool get _isBusy => isExporting || isSelecting || isRestoring;

  Future<bool> exportBackup() async {
    if (_isBusy) return false;
    _status = BackupStatus.exporting;
    _errorMessage = null;
    notifyListeners();
    try {
      _lastExport = await _repository.exportAndShareBackup();
      _status = BackupStatus.success;
      notifyListeners();
      return true;
    } on Object {
      _errorMessage = 'N\u00e3o foi poss\u00edvel criar o backup.';
      _status = BackupStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<BackupImportPreview?> selectBackup() async {
    if (_isBusy) return null;
    _status = BackupStatus.selecting;
    _errorMessage = null;
    _importPreview = null;
    _wasPartialRestore = false;
    notifyListeners();
    try {
      final preview = await _repository.selectAndValidateBackup();
      if (preview == null) {
        _status = BackupStatus.initial;
        notifyListeners();
        return null;
      }
      _importPreview = preview;
      _status = BackupStatus.previewReady;
      notifyListeners();
      return preview;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      _status = BackupStatus.restoreError;
      notifyListeners();
      return null;
    } on Object {
      _errorMessage = 'N\u00e3o foi poss\u00edvel ler o arquivo de backup.';
      _status = BackupStatus.restoreError;
      notifyListeners();
      return null;
    }
  }

  Future<bool> restoreSelectedBackup() async {
    final preview = _importPreview;
    if (preview == null || _isBusy) return false;
    _status = BackupStatus.restoring;
    _errorMessage = null;
    _wasPartialRestore = false;
    notifyListeners();
    try {
      await _repository.restoreBackup(preview.backup);
      _importPreview = null;
      _status = BackupStatus.restoreSuccess;
      notifyListeners();
      return true;
    } on PartialBackupRestoreException catch (error) {
      _importPreview = null;
      _wasPartialRestore = true;
      _errorMessage = error.message;
      _status = BackupStatus.restoreSuccess;
      notifyListeners();
      return true;
    } on Object {
      _errorMessage = 'N\u00e3o foi poss\u00edvel restaurar o backup.';
      _status = BackupStatus.restoreError;
      notifyListeners();
      return false;
    }
  }

  void cancelRestorePreview() {
    if (_isBusy) return;
    _importPreview = null;
    _errorMessage = null;
    _wasPartialRestore = false;
    _status = BackupStatus.initial;
    notifyListeners();
  }

  void clearMessage() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
