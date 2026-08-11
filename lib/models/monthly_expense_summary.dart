class MonthlyExpenseSummary {
  MonthlyExpenseSummary({
    required DateTime month,
    required this.total,
    required this.expenseCount,
  }) : month = DateTime(month.year, month.month);

  final DateTime month;
  final double total;
  final int expenseCount;
}
