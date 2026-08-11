import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanto_posso/core/utils/category_icon_utils.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/inputs/app_text_field.dart';

class ExpenseFormContent extends StatelessWidget {
  const ExpenseFormContent({
    super.key,
    required this.amountController,
    required this.descriptionController,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedDate,
    required this.isSaving,
    required this.amountValidator,
    required this.onCategoryChanged,
    required this.onDateTap,
    required this.onSubmit,
    required this.submitLabel,
    this.categoryValidator,
    this.categoryMessage,
    this.amountLabel = 'Valor do gasto',
    this.dateLabel = 'Data',
    this.afterAmount,
    this.beforeSubmit,
  });

  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final List<ExpenseCategory> categories;
  final String selectedCategoryId;
  final DateTime selectedDate;
  final bool isSaving;
  final FormFieldValidator<String> amountValidator;
  final FormFieldValidator<String>? categoryValidator;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDateTap;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String? categoryMessage;
  final String amountLabel;
  final String dateLabel;
  final Widget? afterAmount;
  final Widget? beforeSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AmountCard(
          controller: amountController,
          enabled: !isSaving,
          validator: amountValidator,
          label: amountLabel,
        ),
        if (afterAmount != null) ...[
          const SizedBox(height: AppSpacing.md),
          afterAmount!,
        ],
        const SizedBox(height: AppSpacing.md),
        _CategorySelector(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          enabled: !isSaving,
          validator: categoryValidator,
          onChanged: onCategoryChanged,
        ),
        if (categoryMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            categoryMessage!,
            style: AppTypography.caption.copyWith(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _DateSelector(
          date: selectedDate,
          enabled: !isSaving,
          onTap: onDateTap,
          label: dateLabel,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: descriptionController,
          label: 'Descrição opcional',
          hint: 'Ex.: Almoço no trabalho',
          prefixIcon: Icons.notes_outlined,
          textInputAction: TextInputAction.done,
          enabled: !isSaving,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (beforeSubmit != null) ...[
          beforeSubmit!,
          const SizedBox(height: AppSpacing.md),
        ],
        PrimaryButton(
          label: submitLabel,
          icon: Icons.check_rounded,
          isLoading: isSaving,
          onPressed: isSaving ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.enabled,
    required this.validator,
    required this.label,
  });

  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      textField: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colorScheme.outline),
          boxShadow: const [AppShadows.card],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: validator,
              style: AppTypography.moneyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              cursorColor: colorScheme.primary,
              decoration: InputDecoration(
                hintText: '0,00',
                prefixText: 'R\$ ',
                prefixStyle: AppTypography.moneyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                hintStyle: AppTypography.moneyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                errorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.enabled,
    required this.validator,
    required this.onChanged,
  });

  final List<ExpenseCategory> categories;
  final String selectedCategoryId;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: selectedCategoryId,
      validator: validator,
      builder: (field) {
        final selected = categories.firstWhere(
          (category) => category.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectionCard(
              semanticLabel: 'Categoria selecionada: ${selected.name}',
              label: 'Categoria',
              value: selected.name,
              leading: _CategoryIcon(category: selected),
              enabled: enabled,
              onTap: () async {
                final value = await _showCategorySheet(
                  context,
                  categories,
                  selectedCategoryId,
                );
                if (value != null) {
                  field.didChange(value);
                  onChanged(value);
                }
              },
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                field.errorText!,
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<String?> _showCategorySheet(
    BuildContext context,
    List<ExpenseCategory> categories,
    String selectedId,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Selecionar categoria',
              style: AppTypography.h3.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final category in categories)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                leading: _CategoryIcon(category: category),
                title: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                trailing: category.id == selectedId
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                selected: category.id == selectedId,
                onTap: () => Navigator.of(sheetContext).pop(category.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final DateTime date;
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      semanticLabel: '$label: ${DateFormat('dd/MM/yyyy').format(date)}',
      label: label,
      value: DateFormat('dd/MM/yyyy').format(date),
      leading: Icon(
        Icons.calendar_today_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.semanticLabel,
    required this.label,
    required this.value,
    required this.leading,
    required this.enabled,
    required this.onTap,
  });

  final String semanticLabel;
  final String label;
  final String value;
  final Widget leading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colorScheme.outline),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
        ? Color(category.colorValue)
        : Theme.of(context).colorScheme.primary;
    final icon = CategoryIconUtils.resolve(category.iconCodePoint);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Icon(icon, color: color),
    );
  }
}
