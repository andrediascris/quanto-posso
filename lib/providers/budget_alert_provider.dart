import 'package:flutter/foundation.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/budget_alert_preferences.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

enum BudgetAlertStatus {
  initial,
  loading,
  ready,
  saving,
  permissionDenied,
  error,
}

class BudgetAlertProvider extends ChangeNotifier {
  BudgetAlertProvider({
    PreferencesRepository? preferencesRepository,
    NotificationScheduler? notificationService,
  }) : _preferencesRepository =
           preferencesRepository ?? PreferencesRepository(),
       _notificationService =
           notificationService ?? LocalNotificationService.instance;

  final PreferencesRepository _preferencesRepository;
  final NotificationScheduler _notificationService;

  BudgetAlertStatus _status = BudgetAlertStatus.initial;
  BudgetAlertPreferences _preferences = BudgetAlertPreferences.defaults;
  String? _errorMessage;
  bool _permissionGranted = false;
  bool _isEvaluatingBudget = false;

  BudgetAlertStatus get status => _status;
  BudgetAlertPreferences get preferences => _preferences;
  String? get errorMessage => _errorMessage;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _status == BudgetAlertStatus.loading;
  bool get isSaving => _status == BudgetAlertStatus.saving;

  Future<void> initialize() async {
    _status = BudgetAlertStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _preferences = await _preferencesRepository.getBudgetAlertPreferences();
      await _notificationService.initialize();
      _permissionGranted = await _notificationService.areNotificationsEnabled();
      _status = _preferences.enabled && !_permissionGranted
          ? BudgetAlertStatus.permissionDenied
          : BudgetAlertStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível carregar os alertas de orçamento.';
      _status = BudgetAlertStatus.error;
    }
    notifyListeners();
  }

  Future<bool> setEnabled(bool enabled) async {
    _status = BudgetAlertStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      if (enabled) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          _permissionGranted = false;
          _preferences = _preferences.copyWith(enabled: false);
          await _preferencesRepository.saveBudgetAlertPreferences(_preferences);
          _status = BudgetAlertStatus.permissionDenied;
          notifyListeners();
          return false;
        }
        _permissionGranted = true;
        final currentPeriod = _currentPeriod();
        _preferences = _preferences.copyWith(
          enabled: true,
          clearLastWarningPeriod:
              _preferences.lastWarningPeriod != null &&
              _preferences.lastWarningPeriod != currentPeriod,
          clearLastLimitPeriod:
              _preferences.lastLimitPeriod != null &&
              _preferences.lastLimitPeriod != currentPeriod,
        );
      } else {
        _preferences = _preferences.copyWith(enabled: false);
      }
      await _preferencesRepository.saveBudgetAlertPreferences(_preferences);
      _status = BudgetAlertStatus.ready;
      notifyListeners();
      return true;
    } on Object {
      _errorMessage = 'Não foi possível atualizar os alertas de orçamento.';
      _status = BudgetAlertStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setThresholdPercentage(int percentage) async {
    if (percentage != 70 && percentage != 80 && percentage != 90) {
      throw ArgumentError.value(
        percentage,
        'percentage',
        'Percentual inválido.',
      );
    }
    _status = BudgetAlertStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      _preferences = _preferences.copyWith(thresholdPercentage: percentage);
      await _preferencesRepository.saveBudgetAlertPreferences(_preferences);
      _status = BudgetAlertStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível atualizar os alertas de orçamento.';
      _status = BudgetAlertStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> evaluateBudget({
    required double monthlyIncome,
    required double monthlyExpenseTotal,
  }) async {
    if (!_preferences.enabled ||
        monthlyIncome <= 0 ||
        !_permissionGranted ||
        _isEvaluatingBudget) {
      return;
    }
    _isEvaluatingBudget = true;
    try {
      final percentage = monthlyExpenseTotal / monthlyIncome * 100;
      final currentPeriod = _currentPeriod();

      if (percentage >= 100) {
        if (_preferences.lastLimitPeriod != currentPeriod) {
          await _notificationService.showBudgetLimitExceeded(
            exceededAmount: monthlyExpenseTotal - monthlyIncome,
          );
          _preferences = _preferences.copyWith(
            lastLimitPeriod: currentPeriod,
            lastWarningPeriod: currentPeriod,
          );
          await _preferencesRepository.saveBudgetAlertPreferences(_preferences);
          notifyListeners();
        }
        return;
      }

      var updated = _preferences;
      var changed = false;
      if (updated.lastLimitPeriod == currentPeriod) {
        updated = updated.copyWith(clearLastLimitPeriod: true);
        changed = true;
      }

      if (percentage >= updated.thresholdPercentage) {
        if (updated.lastWarningPeriod != currentPeriod) {
          await _notificationService.showBudgetWarning(
            percentage: updated.thresholdPercentage,
            remainingAmount: monthlyIncome - monthlyExpenseTotal,
          );
          updated = updated.copyWith(lastWarningPeriod: currentPeriod);
          changed = true;
        }
      } else if (updated.lastWarningPeriod == currentPeriod) {
        updated = updated.copyWith(clearLastWarningPeriod: true);
        changed = true;
      }

      if (changed) {
        _preferences = updated;
        await _preferencesRepository.saveBudgetAlertPreferences(_preferences);
        notifyListeners();
      }
    } on Object {
      _errorMessage = 'Não foi possível avaliar os alertas de orçamento.';
      _status = BudgetAlertStatus.error;
      notifyListeners();
      rethrow;
    } finally {
      _isEvaluatingBudget = false;
    }
  }

  String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
