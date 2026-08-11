import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_type.dart';

class RecurringExpenseBadge extends StatelessWidget {
  const RecurringExpenseBadge({super.key, required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final type = expense.recurringType;
    if (type == null || type == ExpenseType.single) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final installment = type == ExpenseType.installment;
    final label = installment
        ? 'Parcela ${expense.occurrenceNumber} de ${expense.occurrenceTotal}'
        : 'Assinatura';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Wrap(
        spacing: AppSpacing.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            installment
                ? Icons.calendar_view_month_rounded
                : Icons.autorenew_rounded,
            size: AppSpacing.md,
            color: scheme.primary,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
