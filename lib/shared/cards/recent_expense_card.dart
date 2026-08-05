import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';

class RecentExpenseCard extends StatelessWidget {
  const RecentExpenseCard({
    super.key,
    required this.expense,
    required this.category,
    this.onDelete,
    this.onTap,
  });

  final Expense expense;
  final ExpenseCategory category;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // O ícone é reconstruído a partir dos metadados persistidos da categoria.
    final icon = IconData(
      // ignore: non_const_argument_for_const_parameter
      category.iconCodePoint,
      // ignore: non_const_argument_for_const_parameter
      fontFamily: category.iconFontFamily,
    );
    final date = DateFormat('dd/MM/yyyy').format(expense.occurredAt);
    final categoryColor =
        category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
        ? Color(category.colorValue)
        : AppColors.primary;
    final amount = CurrencyUtils.format(expense.amount);
    final description = expense.description?.trim();

    final content = Row(
      children: [
        Icon(icon, color: categoryColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxs),
              Text(
                date,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '- $amount',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
        ),
        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: 'Editar gasto de ${category.name}',
            child: IconButton(
              tooltip: 'Editar gasto',
              onPressed: onTap,
              color: AppColors.primary,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: 'Excluir gasto',
            child: IconButton(
              tooltip: 'Excluir gasto',
              onPressed: onDelete,
              color: AppColors.error,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ],
    );
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: onTap != null,
      label: onTap == null ? null : 'Editar gasto de ${category.name}',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: radius,
          boxShadow: const [AppShadows.card],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: onTap == null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: content,
                )
              : InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}
