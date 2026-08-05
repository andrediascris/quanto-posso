class ReminderPreferences {
  const ReminderPreferences({
    required this.enabled,
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour <= 23),
       assert(minute >= 0 && minute <= 59);

  static const defaults = ReminderPreferences(
    enabled: false,
    hour: 20,
    minute: 0,
  );

  final bool enabled;
  final int hour;
  final int minute;

  ReminderPreferences copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderPreferences(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
