class BudgetAlertPreferences {
  const BudgetAlertPreferences({
    required this.enabled,
    required this.thresholdPercentage,
    required this.lastWarningPeriod,
    required this.lastLimitPeriod,
  }) : assert(
         thresholdPercentage == 70 ||
             thresholdPercentage == 80 ||
             thresholdPercentage == 90,
       );

  static const defaults = BudgetAlertPreferences(
    enabled: false,
    thresholdPercentage: 80,
    lastWarningPeriod: null,
    lastLimitPeriod: null,
  );

  final bool enabled;
  final int thresholdPercentage;
  final String? lastWarningPeriod;
  final String? lastLimitPeriod;

  BudgetAlertPreferences copyWith({
    bool? enabled,
    int? thresholdPercentage,
    String? lastWarningPeriod,
    String? lastLimitPeriod,
    bool clearLastWarningPeriod = false,
    bool clearLastLimitPeriod = false,
  }) {
    return BudgetAlertPreferences(
      enabled: enabled ?? this.enabled,
      thresholdPercentage: thresholdPercentage ?? this.thresholdPercentage,
      lastWarningPeriod: clearLastWarningPeriod
          ? null
          : lastWarningPeriod ?? this.lastWarningPeriod,
      lastLimitPeriod: clearLastLimitPeriod
          ? null
          : lastLimitPeriod ?? this.lastLimitPeriod,
    );
  }
}
