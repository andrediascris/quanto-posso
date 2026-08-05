import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/models/budget_alert_preferences.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

class FakeBudgetPreferencesRepository extends PreferencesRepository {
  FakeBudgetPreferencesRepository({
    this.preferences = BudgetAlertPreferences.defaults,
  });

  BudgetAlertPreferences preferences;
  var saveCount = 0;

  @override
  Future<BudgetAlertPreferences> getBudgetAlertPreferences() async =>
      preferences;

  @override
  Future<void> saveBudgetAlertPreferences(
    BudgetAlertPreferences preferences,
  ) async {
    this.preferences = preferences;
    saveCount++;
  }

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;
}

class FakeBudgetNotificationScheduler implements NotificationScheduler {
  bool permissionGranted = false;
  bool throwOnBudgetNotification = false;
  var warningCount = 0;
  var limitCount = 0;
  int? warningPercentage;
  double? warningRemainingAmount;
  double? limitExceededAmount;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> showBudgetWarning({
    required int percentage,
    required double remainingAmount,
  }) async {
    if (throwOnBudgetNotification) throw StateError('Falha no serviço');
    warningCount++;
    warningPercentage = percentage;
    warningRemainingAmount = remainingAmount;
  }

  @override
  Future<void> showBudgetLimitExceeded({required double exceededAmount}) async {
    if (throwOnBudgetNotification) throw StateError('Falha no serviço');
    limitCount++;
    limitExceededAmount = exceededAmount;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<void> showTestNotification() async {}
}

BudgetAlertProvider createProvider(
  FakeBudgetPreferencesRepository repository,
  FakeBudgetNotificationScheduler scheduler,
) {
  return BudgetAlertProvider(
    preferencesRepository: repository,
    notificationService: scheduler,
  );
}

String currentPeriod() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

const enabledPreferences = BudgetAlertPreferences(
  enabled: true,
  thresholdPercentage: 80,
  lastWarningPeriod: null,
  lastLimitPeriod: null,
);

void main() {
  test('initialize carrega padrão desativado e 80%', () async {
    final repository = FakeBudgetPreferencesRepository();
    final scheduler = FakeBudgetNotificationScheduler();
    final provider = createProvider(repository, scheduler);

    await provider.initialize();

    expect(provider.status, BudgetAlertStatus.ready);
    expect(provider.preferences.enabled, isFalse);
    expect(provider.preferences.thresholdPercentage, 80);
  });

  test('ativar com permissão concedida persiste enabled true', () async {
    final repository = FakeBudgetPreferencesRepository();
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    final result = await provider.setEnabled(true);

    expect(result, isTrue);
    expect(provider.preferences.enabled, isTrue);
    expect(repository.preferences.enabled, isTrue);
  });

  test('ativar com permissão negada mantém enabled false', () async {
    final repository = FakeBudgetPreferencesRepository();
    final scheduler = FakeBudgetNotificationScheduler();
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    final result = await provider.setEnabled(true);

    expect(result, isFalse);
    expect(provider.preferences.enabled, isFalse);
    expect(provider.status, BudgetAlertStatus.permissionDenied);
  });

  test('percentual abaixo do limite não envia notificação', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 799,
    );

    expect(scheduler.warningCount, 0);
    expect(scheduler.limitCount, 0);
  });

  test('atingir 80% envia warning uma vez', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 800,
    );

    expect(scheduler.warningCount, 1);
    expect(scheduler.warningPercentage, 80);
    expect(scheduler.warningRemainingAmount, 200);
    expect(provider.preferences.lastWarningPeriod, currentPeriod());
  });

  test('avaliar novamente no mesmo mês não duplica warning', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 800,
    );
    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 900,
    );

    expect(scheduler.warningCount, 1);
  });

  test('atingir 100% envia somente limite', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 1000,
    );

    expect(scheduler.limitCount, 1);
    expect(scheduler.warningCount, 0);
    expect(provider.preferences.lastLimitPeriod, currentPeriod());
    expect(provider.preferences.lastWarningPeriod, currentPeriod());
  });

  test('avaliar novamente acima de 100% não duplica limite', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 1100,
    );
    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 1200,
    );

    expect(scheduler.limitCount, 1);
    expect(scheduler.limitExceededAmount, 100);
  });

  test('cair abaixo de 80% limpa o estado do warning', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: BudgetAlertPreferences(
        enabled: true,
        thresholdPercentage: 80,
        lastWarningPeriod: currentPeriod(),
        lastLimitPeriod: null,
      ),
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 700,
    );

    expect(provider.preferences.lastWarningPeriod, isNull);
  });

  test('após cair abaixo e subir novamente envia novo warning', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 800,
    );
    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 700,
    );
    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 850,
    );

    expect(scheduler.warningCount, 2);
  });

  test('cair abaixo de 100% limpa o estado do limite', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: BudgetAlertPreferences(
        enabled: true,
        thresholdPercentage: 80,
        lastWarningPeriod: currentPeriod(),
        lastLimitPeriod: currentPeriod(),
      ),
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 900,
    );

    expect(provider.preferences.lastLimitPeriod, isNull);
  });

  test('mudar para novo mês permite novo alerta', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: const BudgetAlertPreferences(
        enabled: true,
        thresholdPercentage: 80,
        lastWarningPeriod: '2000-01',
        lastLimitPeriod: null,
      ),
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await provider.evaluateBudget(
      monthlyIncome: 1000,
      monthlyExpenseTotal: 800,
    );

    expect(scheduler.warningCount, 1);
    expect(provider.preferences.lastWarningPeriod, currentPeriod());
  });

  test('setThresholdPercentage aceita 70, 80 e 90', () async {
    final repository = FakeBudgetPreferencesRepository();
    final scheduler = FakeBudgetNotificationScheduler();
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    for (final percentage in [70, 80, 90]) {
      await provider.setThresholdPercentage(percentage);
      expect(provider.preferences.thresholdPercentage, percentage);
    }
  });

  test('percentual inválido lança ArgumentError', () async {
    final provider = createProvider(
      FakeBudgetPreferencesRepository(),
      FakeBudgetNotificationScheduler(),
    );
    await provider.initialize();

    expect(
      () => provider.setThresholdPercentage(75),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('erro no serviço define status error', () async {
    final repository = FakeBudgetPreferencesRepository(
      preferences: enabledPreferences,
    );
    final scheduler = FakeBudgetNotificationScheduler()
      ..permissionGranted = true
      ..throwOnBudgetNotification = true;
    final provider = createProvider(repository, scheduler);
    await provider.initialize();

    await expectLater(
      provider.evaluateBudget(monthlyIncome: 1000, monthlyExpenseTotal: 800),
      throwsA(isA<StateError>()),
    );

    expect(provider.status, BudgetAlertStatus.error);
  });
}
