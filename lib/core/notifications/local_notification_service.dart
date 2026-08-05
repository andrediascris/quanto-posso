import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class NotificationScheduler {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> areNotificationsEnabled();
  Future<void> scheduleDailyReminder({required int hour, required int minute});
  Future<void> cancelDailyReminder();
  Future<void> showTestNotification();
  Future<void> showBudgetWarning({
    required int percentage,
    required double remainingAmount,
  });
  Future<void> showBudgetLimitExceeded({required double exceededAmount});
}

class LocalNotificationService implements NotificationScheduler {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const _dailyReminderId = 1001;
  static const _testNotificationId = 1002;
  static const _channelId = 'daily_expense_reminder';
  static const _channelName = 'Lembrete diário';
  static const _channelDescription =
      'Lembretes para registrar os gastos do dia';
  static const _budgetWarningId = 2001;
  static const _budgetLimitId = 2002;
  static const _budgetChannelId = 'budget_alerts';
  static const _budgetChannelName = 'Alertas de orçamento';
  static const _budgetChannelDescription =
      'Alertas sobre o consumo do orçamento mensal';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Future<void>? _initialization;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    final initialization = _initialization;
    if (initialization != null) return initialization;
    final operation = _initialize();
    _initialization = operation;
    try {
      await operation;
    } finally {
      if (!_isInitialized) _initialization = null;
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Horário inválido.');
    }
    await initialize();
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Já registrou seus gastos de hoje?',
      body:
          'Abra o Quanto Posso e mantenha seu controle financeiro atualizado.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _channelId,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  @override
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: _testNotificationId,
      title: 'Quanto Posso',
      body: 'As notificações estão funcionando corretamente.',
      notificationDetails: _notificationDetails,
    );
  }

  @override
  Future<void> showBudgetWarning({
    required int percentage,
    required double remainingAmount,
  }) async {
    await initialize();
    await _plugin.show(
      id: _budgetWarningId,
      title: 'Atenção ao seu orçamento',
      body:
          'Você já utilizou $percentage% da sua renda mensal. '
          'Ainda restam ${CurrencyUtils.format(remainingAmount)}.',
      notificationDetails: _budgetNotificationDetails,
      payload: 'budget_warning',
    );
  }

  @override
  Future<void> showBudgetLimitExceeded({required double exceededAmount}) async {
    await initialize();
    await _plugin.show(
      id: _budgetLimitId,
      title: 'Limite mensal ultrapassado',
      body: exceededAmount > 0
          ? 'Seus gastos ultrapassaram sua renda em '
                '${CurrencyUtils.format(exceededAmount)}.'
          : 'Você atingiu 100% da sua renda mensal.',
      notificationDetails: _budgetNotificationDetails,
      payload: 'budget_limit_exceeded',
    );
  }

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const _budgetNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _budgetChannelId,
      _budgetChannelName,
      channelDescription: _budgetChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}
