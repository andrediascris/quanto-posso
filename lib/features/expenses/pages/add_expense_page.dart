import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/inputs/app_text_field.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({
    super.key,
    required this.categories,
    required this.onSave,
  }) : assert(categories.length > 0);

  final List<ExpenseCategory> categories;
  final Future<void> Function({
    required double amount,
    required String categoryId,
    String? description,
    required DateTime occurredAt,
  })
  onSave;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categories.first.id;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Informe o valor do gasto';
    }

    final amount = CurrencyUtils.tryParse(text);
    if (amount == null || !(amount > 0)) {
      return 'Informe um valor válido';
    }

    return null;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (selectedDate != null && mounted) {
      setState(() => _selectedDate = selectedDate);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    final amount = CurrencyUtils.tryParse(_amountController.text);
    if (amount == null) {
      return;
    }

    final trimmedDescription = _descriptionController.text.trim();
    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        amount: amount,
        categoryId: _selectedCategoryId,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
        occurredAt: _selectedDate,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Não foi possível salvar o gasto.',
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.medium);
    final inputBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Adicionar gasto',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Novo gasto',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Registre rapidamente o que você gastou.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _amountController,
                  label: 'Valor',
                  hint: 'Ex.: 25,90',
                  prefixText: 'R\$ ',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _validateAmount,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  dropdownColor: AppColors.surfaceLight,
                  iconEnabledColor: AppColors.primary,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(
                                // O ícone vem dos metadados da categoria.
                                IconData(
                                  // ignore: non_const_argument_for_const_parameter
                                  category.iconCodePoint,
                                  // ignore: non_const_argument_for_const_parameter
                                  fontFamily: category.iconFontFamily,
                                ),
                                color:
                                    category.colorValue >= 0 &&
                                        category.colorValue <= 0xFFFFFFFF
                                    ? Color(category.colorValue)
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(category.name),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedCategoryId = value);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: _isSaving ? null : _selectDate,
                    borderRadius: borderRadius,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descrição opcional',
                  hint: 'Ex.: Almoço no trabalho',
                  prefixIcon: Icons.notes_rounded,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Salvar gasto',
                  icon: Icons.check_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
