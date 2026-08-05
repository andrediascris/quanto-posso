import 'package:flutter/foundation.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/reminder_preferences.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

enum NotificationStatus {
  initial,
  loading,
  ready,
  saving,
  permissionDenied,
  error,
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    PreferencesRepository? preferencesRepository,
    NotificationScheduler? notificationService,
  }) : _preferencesRepository =
           preferencesRepository ?? PreferencesRepository(),
       _notificationService =
           notificationService ?? LocalNotificationService.instance;

  final PreferencesRepository _preferencesRepository;
  final NotificationScheduler _notificationService;

  NotificationStatus _status = NotificationStatus.initial;
  ReminderPreferences _preferences = ReminderPreferences.defaults;
  bool _permissionGranted = false;
  String? _errorMessage;

  NotificationStatus get status => _status;
  ReminderPreferences get preferences => _preferences;
  bool get permissionGranted => _permissionGranted;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationStatus.loading;
  bool get isSaving => _status == NotificationStatus.saving;

  Future<void> initialize() async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _notificationService.initialize();
      _preferences = await _preferencesRepository.getReminderPreferences();
      _permissionGranted = await _notificationService.areNotificationsEnabled();
      if (_preferences.enabled && _permissionGranted) {
        await _notificationService.scheduleDailyReminder(
          hour: _preferences.hour,
          minute: _preferences.minute,
        );
        _status = NotificationStatus.ready;
      } else if (_preferences.enabled) {
        _status = NotificationStatus.permissionDenied;
      } else {
        _status = NotificationStatus.ready;
      }
    } on Object {
      _errorMessage =
          'Não foi possível carregar as configurações de notificações.';
      _status = NotificationStatus.error;
    }
    notifyListeners();
  }

  Future<bool> setEnabled(bool enabled) async {
    _status = NotificationStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      if (enabled) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          _permissionGranted = false;
          _preferences = _preferences.copyWith(enabled: false);
          await _preferencesRepository.saveReminderPreferences(_preferences);
          _status = NotificationStatus.permissionDenied;
          notifyListeners();
          return false;
        }

        final updated = _preferences.copyWith(enabled: true);
        await _preferencesRepository.saveReminderPreferences(updated);
        await _notificationService.scheduleDailyReminder(
          hour: updated.hour,
          minute: updated.minute,
        );
        _preferences = updated;
        _permissionGranted = true;
      } else {
        await _notificationService.cancelDailyReminder();
        _preferences = _preferences.copyWith(enabled: false);
        await _preferencesRepository.saveReminderPreferences(_preferences);
      }
      _status = NotificationStatus.ready;
      notifyListeners();
      return true;
    } on Object {
      _errorMessage = 'Não foi possível atualizar o lembrete.';
      _status = NotificationStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setTime({required int hour, required int minute}) async {
    _status = NotificationStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = _preferences.copyWith(hour: hour, minute: minute);
      await _preferencesRepository.saveReminderPreferences(updated);
      if (updated.enabled && _permissionGranted) {
        await _notificationService.scheduleDailyReminder(
          hour: updated.hour,
          minute: updated.minute,
        );
      }
      _preferences = updated;
      _status = NotificationStatus.ready;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível atualizar o lembrete.';
      _status = NotificationStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> sendTestNotification() async {
    _status = NotificationStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      await _notificationService.initialize();
      var granted = _permissionGranted;
      if (!granted) {
        granted = await _notificationService.requestPermission();
      }
      if (!granted) {
        _permissionGranted = false;
        _status = NotificationStatus.permissionDenied;
        notifyListeners();
        return false;
      }
      _permissionGranted = true;
      await _notificationService.showTestNotification();
      _status = NotificationStatus.ready;
      notifyListeners();
      return true;
    } on Object {
      _errorMessage = 'Não foi possível enviar a notificação de teste.';
      _status = NotificationStatus.error;
      notifyListeners();
      rethrow;
    }
  }
}
