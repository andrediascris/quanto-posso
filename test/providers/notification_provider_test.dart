import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/reminder_preferences.dart';
import 'package:quanto_posso/providers/notification_provider.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

class FakePreferencesRepository extends PreferencesRepository {
  FakePreferencesRepository({
    this.reminderPreferences = ReminderPreferences.defaults,
  });

  ReminderPreferences reminderPreferences;
  var saveCount = 0;

  @override
  Future<ReminderPreferences> getReminderPreferences() async =>
      reminderPreferences;

  @override
  Future<void> saveReminderPreferences(ReminderPreferences preferences) async {
    reminderPreferences = preferences;
    saveCount++;
  }

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;
}

class FakeNotificationScheduler implements NotificationScheduler {
  bool permissionGranted = false;
  bool throwWhenScheduling = false;
  var initializeCount = 0;
  var scheduleCount = 0;
  var cancelCount = 0;
  var testNotificationCount = 0;
  int? scheduledHour;
  int? scheduledMinute;

  @override
  Future<void> initialize() async => initializeCount++;

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (throwWhenScheduling) throw StateError('Falha ao agendar');
    scheduleCount++;
    scheduledHour = hour;
    scheduledMinute = minute;
  }

  @override
  Future<void> cancelDailyReminder() async => cancelCount++;

  @override
  Future<void> showTestNotification() async => testNotificationCount++;

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

NotificationProvider createProvider(
  FakePreferencesRepository repository,
  FakeNotificationScheduler scheduler,
) {
  return NotificationProvider(
    preferencesRepository: repository,
    notificationService: scheduler,
  );
}

void main() {
  test('initialize carrega preferências desativadas', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler();
    final provider = createProvider(repository, scheduler);

    await provider.initialize();

    expect(provider.status, NotificationStatus.ready);
    expect(provider.preferences.enabled, isFalse);
    expect(provider.preferences.hour, 20);
    expect(provider.preferences.minute, 0);
    expect(scheduler.scheduleCount, 0);
  });

  test('ativar com permissão concedida persiste e agenda', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler()..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    final enabled = await provider.setEnabled(true);

    expect(enabled, isTrue);
    expect(repository.reminderPreferences.enabled, isTrue);
    expect(provider.preferences.enabled, isTrue);
    expect(scheduler.scheduleCount, 1);
    expect(scheduler.scheduledHour, 20);
  });

  test('ativar com permissão negada mantém desativado', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler();
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    final enabled = await provider.setEnabled(true);

    expect(enabled, isFalse);
    expect(provider.preferences.enabled, isFalse);
    expect(repository.reminderPreferences.enabled, isFalse);
    expect(provider.status, NotificationStatus.permissionDenied);
    expect(scheduler.scheduleCount, 0);
  });

  test('desativar cancela o lembrete', () async {
    final repository = FakePreferencesRepository(
      reminderPreferences: const ReminderPreferences(
        enabled: true,
        hour: 20,
        minute: 0,
      ),
    );
    final scheduler = FakeNotificationScheduler()..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.setEnabled(false);

    expect(scheduler.cancelCount, 1);
    expect(provider.preferences.enabled, isFalse);
  });

  test('alterar horário reagenda quando ativado', () async {
    final repository = FakePreferencesRepository(
      reminderPreferences: const ReminderPreferences(
        enabled: true,
        hour: 20,
        minute: 0,
      ),
    );
    final scheduler = FakeNotificationScheduler()..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();
    final schedulesAfterInitialize = scheduler.scheduleCount;

    await provider.setTime(hour: 21, minute: 30);

    expect(scheduler.scheduleCount, schedulesAfterInitialize + 1);
    expect(scheduler.scheduledHour, 21);
    expect(scheduler.scheduledMinute, 30);
    expect(repository.reminderPreferences.hour, 21);
  });

  test('alterar horário não agenda quando desativado', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler()..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.setTime(hour: 8, minute: 15);

    expect(scheduler.scheduleCount, 0);
    expect(provider.preferences.hour, 8);
    expect(provider.preferences.minute, 15);
  });

  test('erro ao agendar define status error', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler()
      ..permissionGranted = true
      ..throwWhenScheduling = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await expectLater(provider.setEnabled(true), throwsA(isA<StateError>()));

    expect(provider.status, NotificationStatus.error);
    expect(provider.errorMessage, 'Não foi possível atualizar o lembrete.');
  });

  test('teste de notificação chama o scheduler', () async {
    final repository = FakePreferencesRepository();
    final scheduler = FakeNotificationScheduler()..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    final sent = await provider.sendTestNotification();

    expect(sent, isTrue);
    expect(scheduler.testNotificationCount, 1);
  });
}
