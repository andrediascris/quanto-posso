import 'package:quanto_posso/models/expense_type.dart';

class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.recurringPlanId,
    this.occurrenceNumber,
    this.occurrenceTotal,
    this.recurringType,
  });

  final int? id;
  final double amount;
  final String categoryId;
  final String? description;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? recurringPlanId;
  final int? occurrenceNumber;
  final int? occurrenceTotal;
  final ExpenseType? recurringType;

  Expense copyWith({
    int? id,
    double? amount,
    String? categoryId,
    String? description,
    bool clearDescription = false,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? recurringPlanId,
    int? occurrenceNumber,
    int? occurrenceTotal,
    ExpenseType? recurringType,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: clearDescription ? null : description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurringPlanId: recurringPlanId ?? this.recurringPlanId,
      occurrenceNumber: occurrenceNumber ?? this.occurrenceNumber,
      occurrenceTotal: occurrenceTotal ?? this.occurrenceTotal,
      recurringType: recurringType ?? this.recurringType,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'recurring_plan_id': recurringPlanId,
      'occurrence_number': occurrenceNumber,
      'occurrence_total': occurrenceTotal,
      'recurring_type': recurringType?.storageValue,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      description: map['description'] as String?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      recurringPlanId: map['recurring_plan_id'] as int?,
      occurrenceNumber: map['occurrence_number'] as int?,
      occurrenceTotal: map['occurrence_total'] as int?,
      recurringType: map['recurring_type'] == null
          ? null
          : ExpenseType.fromStorage(map['recurring_type'] as String?),
    );
  }
}
