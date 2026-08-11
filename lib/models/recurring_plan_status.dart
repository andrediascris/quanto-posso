enum RecurringPlanStatus {
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const RecurringPlanStatus(this.storageValue);
  final String storageValue;

  static RecurringPlanStatus fromStorage(
    String? value, {
    required bool isActive,
    required int generatedOccurrences,
    required int? totalOccurrences,
  }) {
    for (final status in values) {
      if (status.storageValue == value) return status;
    }
    if (isActive) return active;
    if (totalOccurrences != null && generatedOccurrences >= totalOccurrences) {
      return completed;
    }
    return cancelled;
  }
}
