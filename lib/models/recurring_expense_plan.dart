import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';

class RecurringExpensePlan {
  const RecurringExpensePlan({
    this.id,
    required this.type,
    required this.categoryId,
    this.description,
    required this.amount,
    required this.startDate,
    required this.billingDay,
    this.totalOccurrences,
    this.generatedOccurrences = 0,
    this.isActive = true,
    this.status = RecurringPlanStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final ExpenseType type;
  final String categoryId;
  final String? description;
  final double amount;
  final DateTime startDate;
  final int billingDay;
  final int? totalOccurrences;
  final int generatedOccurrences;
  final bool isActive;
  final RecurringPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.storageValue,
    'category_id': categoryId,
    'description': description,
    'amount': amount,
    'start_date': startDate.toIso8601String(),
    'billing_day': billingDay,
    'total_occurrences': totalOccurrences,
    'generated_occurrences': generatedOccurrences,
    'is_active': isActive ? 1 : 0,
    'status': status.storageValue,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory RecurringExpensePlan.fromMap(Map<String, Object?> map) {
    final generatedOccurrences = map['generated_occurrences'] as int;
    final totalOccurrences = map['total_occurrences'] as int?;
    final isActive = (map['is_active'] as int) == 1;
    return RecurringExpensePlan(
      id: map['id'] as int?,
      type: ExpenseType.fromStorage(map['type'] as String?),
      categoryId: map['category_id'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      billingDay: map['billing_day'] as int,
      totalOccurrences: totalOccurrences,
      generatedOccurrences: generatedOccurrences,
      isActive: isActive,
      status: RecurringPlanStatus.fromStorage(
        map['status'] as String?,
        isActive: isActive,
        generatedOccurrences: generatedOccurrences,
        totalOccurrences: totalOccurrences,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
