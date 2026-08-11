import 'package:flutter/material.dart';
import 'package:quanto_posso/core/utils/category_icon_utils.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/recurring/widgets/recurring_status_chip.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

class RecurringPlanCard extends StatelessWidget {
  const RecurringPlanCard({
    super.key,
    required this.plan,
    required this.category,
    required this.onTap,
  });

  final RecurringExpensePlan plan;
  final ExpenseCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = plan.description?.trim().isNotEmpty == true
        ? plan.description!.trim()
        : category.name;
    final next = RecurringExpenseProvider.nextOccurrence(plan);
    final installment = plan.type == ExpenseType.installment;
    final nextAmount = installment
        ? RecurringExpenseRepository.occurrenceAmount(
            plan,
            (plan.generatedOccurrences + 1).clamp(1, plan.totalOccurrences!),
          )
        : plan.amount;
    final icon = CategoryIconUtils.resolve(category.iconCodePoint);
    final progress = plan.totalOccurrences == null
        ? null
        : (plan.generatedOccurrences / plan.totalOccurrences!).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: '$title, ${category.name}',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: const [AppShadows.card],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${CurrencyUtils.format(nextAmount)} por mês',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _detail(next),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.small.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Semantics(
                          label:
                              '${plan.generatedOccurrences} de ${plan.totalOccurrences} ocorrências',
                          child: LinearProgressIndicator(value: progress),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      RecurringStatusChip(status: plan.status, type: plan.type),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _detail(DateTime? next) {
    if (plan.status == RecurringPlanStatus.completed) {
      final unit = plan.type == ExpenseType.subscription
          ? 'meses concluídos'
          : 'parcelas concluídas';
      return '${plan.generatedOccurrences} de ${plan.totalOccurrences} $unit';
    }
    if (next == null) return 'Sem próximas cobranças';
    final date = DateFormat('dd/MM/yyyy').format(next);
    if (plan.type == ExpenseType.subscription) {
      final duration = plan.totalOccurrences == null
          ? 'Até cancelar'
          : '${plan.generatedOccurrences} de ${plan.totalOccurrences} meses gerados';
      return '$duration · Próxima cobrança: $date';
    }
    return 'Parcela ${plan.generatedOccurrences} de ${plan.totalOccurrences} · Próxima: $date';
  }
}
