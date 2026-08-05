import 'package:flutter/material.dart';
import 'package:quanto_posso/models/reminder_preferences.dart';
import 'package:quanto_posso/models/budget_alert_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  static const _themeModeKey = 'theme_mode';
  static const _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const _dailyReminderHourKey = 'daily_reminder_hour';
  static const _dailyReminderMinuteKey = 'daily_reminder_minute';
  static const _budgetAlertEnabledKey = 'budget_alert_enabled';
  static const _budgetAlertThresholdKey = 'budget_alert_threshold';
  static const _budgetAlertLastWarningPeriodKey =
      'budget_alert_last_warning_period';
  static const _budgetAlertLastLimitPeriodKey =
      'budget_alert_last_limit_period';

  Future<ThemeMode> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' || _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
    await preferences.setString(_themeModeKey, value);
  }

  Future<ReminderPreferences> getReminderPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final hour = preferences.getInt(_dailyReminderHourKey);
    final minute = preferences.getInt(_dailyReminderMinuteKey);
    final hasValidTime =
        hour != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute != null &&
        minute >= 0 &&
        minute <= 59;

    return ReminderPreferences(
      enabled: preferences.getBool(_dailyReminderEnabledKey) ?? false,
      hour: hasValidTime ? hour : ReminderPreferences.defaults.hour,
      minute: hasValidTime ? minute : ReminderPreferences.defaults.minute,
    );
  }

  Future<void> saveReminderPreferences(
    ReminderPreferences reminderPreferences,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _dailyReminderEnabledKey,
      reminderPreferences.enabled,
    );
    await preferences.setInt(_dailyReminderHourKey, reminderPreferences.hour);
    await preferences.setInt(
      _dailyReminderMinuteKey,
      reminderPreferences.minute,
    );
  }

  Future<BudgetAlertPreferences> getBudgetAlertPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final threshold = preferences.getInt(_budgetAlertThresholdKey);
    final validThreshold =
        threshold == 70 || threshold == 80 || threshold == 90;
    final warningPeriod = preferences
        .getString(_budgetAlertLastWarningPeriodKey)
        ?.trim();
    final limitPeriod = preferences
        .getString(_budgetAlertLastLimitPeriodKey)
        ?.trim();

    return BudgetAlertPreferences(
      enabled: preferences.getBool(_budgetAlertEnabledKey) ?? false,
      thresholdPercentage: validThreshold ? threshold! : 80,
      lastWarningPeriod: warningPeriod == null || warningPeriod.isEmpty
          ? null
          : warningPeriod,
      lastLimitPeriod: limitPeriod == null || limitPeriod.isEmpty
          ? null
          : limitPeriod,
    );
  }

  Future<void> saveBudgetAlertPreferences(
    BudgetAlertPreferences budgetAlertPreferences,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _budgetAlertEnabledKey,
      budgetAlertPreferences.enabled,
    );
    await preferences.setInt(
      _budgetAlertThresholdKey,
      budgetAlertPreferences.thresholdPercentage,
    );
    if (budgetAlertPreferences.lastWarningPeriod == null) {
      await preferences.remove(_budgetAlertLastWarningPeriodKey);
    } else {
      await preferences.setString(
        _budgetAlertLastWarningPeriodKey,
        budgetAlertPreferences.lastWarningPeriod!,
      );
    }
    if (budgetAlertPreferences.lastLimitPeriod == null) {
      await preferences.remove(_budgetAlertLastLimitPeriodKey);
    } else {
      await preferences.setString(
        _budgetAlertLastLimitPeriodKey,
        budgetAlertPreferences.lastLimitPeriod!,
      );
    }
  }

  Future<Map<String, Object?>> exportPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    const keys = [
      _themeModeKey,
      _dailyReminderEnabledKey,
      _dailyReminderHourKey,
      _dailyReminderMinuteKey,
      _budgetAlertEnabledKey,
      _budgetAlertThresholdKey,
      _budgetAlertLastWarningPeriodKey,
      _budgetAlertLastLimitPeriodKey,
    ];
    final exported = <String, Object?>{};
    for (final key in keys) {
      if (preferences.containsKey(key)) {
        exported[key] = preferences.get(key);
      }
    }
    return exported;
  }

  void validateImportPreferences(Map<String, Object?> preferences) {
    _validateOptional<String>(preferences, _themeModeKey, (value) {
      return value == 'system' || value == 'light' || value == 'dark';
    });
    _validateOptional<bool>(preferences, _dailyReminderEnabledKey);
    _validateOptional<int>(
      preferences,
      _dailyReminderHourKey,
      (value) => value >= 0 && value <= 23,
    );
    _validateOptional<int>(
      preferences,
      _dailyReminderMinuteKey,
      (value) => value >= 0 && value <= 59,
    );
    _validateOptional<bool>(preferences, _budgetAlertEnabledKey);
    _validateOptional<int>(
      preferences,
      _budgetAlertThresholdKey,
      (value) => value == 70 || value == 80 || value == 90,
    );
    _validateOptional<String>(preferences, _budgetAlertLastWarningPeriodKey);
    _validateOptional<String>(preferences, _budgetAlertLastLimitPeriodKey);
  }

  Future<void> importPreferences(Map<String, Object?> preferences) async {
    validateImportPreferences(preferences);
    final storage = await SharedPreferences.getInstance();
    for (final key in _knownKeys) {
      if (!preferences.containsKey(key)) {
        if (!await storage.remove(key)) {
          throw StateError('Falha ao remover prefer\u00eancia.');
        }
        continue;
      }
      final value = preferences[key];
      final bool saved;
      if (value is String) {
        saved = await storage.setString(key, value);
      } else if (value is bool) {
        saved = await storage.setBool(key, value);
      } else if (value is int) {
        saved = await storage.setInt(key, value);
      } else {
        throw StateError('Falha ao importar prefer\u00eancia.');
      }
      if (!saved) {
        throw StateError('Falha ao importar prefer\u00eancia.');
      }
    }
  }

  static const _knownKeys = {
    _themeModeKey,
    _dailyReminderEnabledKey,
    _dailyReminderHourKey,
    _dailyReminderMinuteKey,
    _budgetAlertEnabledKey,
    _budgetAlertThresholdKey,
    _budgetAlertLastWarningPeriodKey,
    _budgetAlertLastLimitPeriodKey,
  };

  void _validateOptional<T>(
    Map<String, Object?> preferences,
    String key, [
    bool Function(T value)? isValid,
  ]) {
    if (!preferences.containsKey(key)) return;
    final value = preferences[key];
    if (value is! T || (isValid != null && !isValid(value))) {
      throw FormatException('Prefer\u00eancia inv\u00e1lida: $key.');
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_themeModeKey);
    await preferences.remove(_dailyReminderEnabledKey);
    await preferences.remove(_dailyReminderHourKey);
    await preferences.remove(_dailyReminderMinuteKey);
    await preferences.remove(_budgetAlertEnabledKey);
    await preferences.remove(_budgetAlertThresholdKey);
    await preferences.remove(_budgetAlertLastWarningPeriodKey);
    await preferences.remove(_budgetAlertLastLimitPeriodKey);
  }
}
