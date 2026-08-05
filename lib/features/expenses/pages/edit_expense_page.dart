import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/inputs/app_text_field.dart';

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({
    super.key,
    required this.expense,
    required this.categories,
    required this.onSave,
  }) : assert(categories.length > 0);

  final Expense expense;
  final List<ExpenseCategory> categories;
  final Future<void> Function({
    required Expense expense,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime occurredAt,
  })
  onSave;

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  late bool _originalCategoryUnavailable;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: CurrencyUtils.formatForInput(widget.expense.amount),
    );
    _descriptionController = TextEditingController(
      text: widget.expense.description ?? '',
    );
    _originalCategoryUnavailable = !widget.categories.any(
      (category) => category.id == widget.expense.categoryId,
    );
    _selectedCategoryId = _originalCategoryUnavailable
        ? widget.categories.first.id
        : widget.expense.categoryId;
    _selectedDate = widget.expense.occurredAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o valor do gasto';
    final amount = CurrencyUtils.tryParse(text);
    if (amount == null || !(amount > 0)) {
      return 'Informe um valor v\u00e1lido';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma data v\u00e1lida.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final amount = CurrencyUtils.tryParse(_amountController.text);
    if (amount == null) return;
    final description = _descriptionController.text.trim();
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        expense: widget.expense,
        amount: amount,
        categoryId: _selectedCategoryId,
        description: description.isEmpty ? null : description,
        occurredAt: _selectedDate,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('N\u00e3o foi poss\u00edvel atualizar o gasto.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      appBar: AppBar(title: const Text('Editar gasto')),
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
                  'Atualize o lan\u00e7amento',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Corrija as informa\u00e7\u00f5es deste gasto.',
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
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  dropdownColor: AppColors.surfaceLight,
                  iconEnabledColor: AppColors.primary,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (value) {
                    final isValid = widget.categories.any(
                      (category) => category.id == value,
                    );
                    if (!isValid || _originalCategoryUnavailable) {
                      return 'Selecione uma categoria v\u00e1lida';
                    }
                    return null;
                  },
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(
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
                            setState(() {
                              _selectedCategoryId = value;
                              _originalCategoryUnavailable = false;
                            });
                          }
                        },
                ),
                if (_originalCategoryUnavailable) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A categoria original n\u00e3o est\u00e1 dispon\u00edvel. '
                    'Confirme a nova categoria antes de salvar.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
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
                  label: 'Descri\u00e7\u00e3o opcional',
                  prefixIcon: Icons.notes_rounded,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Salvar altera\u00e7\u00f5es',
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
