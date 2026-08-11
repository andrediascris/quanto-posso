import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';

class RecurringStatusChip extends StatelessWidget {
  const RecurringStatusChip({
    super.key,
    required this.status,
    required this.type,
  });

  final RecurringPlanStatus status;
  final ExpenseType type;

  @override
  Widget build(BuildContext context) {
    final cancelled = status == RecurringPlanStatus.cancelled;
    final label = switch (status) {
      RecurringPlanStatus.active => 'Ativa',
      RecurringPlanStatus.completed => 'Concluída',
      RecurringPlanStatus.cancelled =>
        type == ExpenseType.subscription ? 'Cancelada' : 'Encerrado',
    };
    final color = cancelled ? AppColors.error : AppColors.success;
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: AppTypography.small.copyWith(color: color),
        ),
      ),
    );
  }
}
