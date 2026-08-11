import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/expenses/widgets/expense_form_content.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';

enum RecurringEditScope { onlyThis, thisAndFuture }

Future<RecurringEditScope?> showRecurringEditScopeSheet(BuildContext context) {
  return showModalBottomSheet<RecurringEditScope>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aplicar alteração em:',
              style: AppTypography.h3.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Somente este lançamento'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(RecurringEditScope.onlyThis),
            ),
            ListTile(
              leading: const Icon(Icons.update_rounded),
              title: const Text('Este e os próximos'),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(RecurringEditScope.thisAndFuture),
            ),
          ],
        ),
      ),
    ),
  );
}

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({
    super.key,
    required this.expense,
    required this.categories,
    required this.onSave,
    this.recurringEditScope = RecurringEditScope.onlyThis,
    this.nextBillingDate,
  }) : assert(categories.length > 0);

  final Expense expense;
  final RecurringEditScope recurringEditScope;
  final DateTime? nextBillingDate;
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
    _selectedDate =
        widget.recurringEditScope == RecurringEditScope.thisAndFuture
        ? widget.nextBillingDate ?? widget.expense.occurredAt
        : widget.expense.occurredAt;
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
      return 'Informe um valor válido';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final editsFuture =
        widget.recurringEditScope == RecurringEditScope.thisAndFuture;
    final selected = await showDatePicker(
      context: context,
      initialDate: editsFuture || !_selectedDate.isAfter(now)
          ? _selectedDate
          : now,
      firstDate: DateTime(2020),
      lastDate: editsFuture ? DateTime(now.year + 20) : now,
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    if (widget.recurringEditScope == RecurringEditScope.onlyThis &&
        _selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma data válida.')),
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
          const SnackBar(content: Text('Não foi possível atualizar o gasto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar gasto'),
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Atualize o lançamento',
                  style: AppTypography.h2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Corrija as informações deste gasto.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.expense.recurringPlanId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.recurringEditScope == RecurringEditScope.onlyThis
                        ? 'Esta alteração será aplicada somente a este lançamento.'
                        : 'O histórico anterior será preservado. As novas regras valerão para as próximas cobranças.',
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ExpenseFormContent(
                  amountController: _amountController,
                  descriptionController: _descriptionController,
                  categories: widget.categories,
                  selectedCategoryId: _selectedCategoryId,
                  selectedDate: _selectedDate,
                  isSaving: _isSaving,
                  amountValidator: _validateAmount,
                  categoryValidator: (value) {
                    final isValid = widget.categories.any(
                      (category) => category.id == value,
                    );
                    if (!isValid || _originalCategoryUnavailable) {
                      return 'Selecione uma categoria válida';
                    }
                    return null;
                  },
                  categoryMessage: _originalCategoryUnavailable
                      ? 'A categoria original não está disponível. '
                            'Confirme a nova categoria antes de salvar.'
                      : null,
                  onCategoryChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _originalCategoryUnavailable = false;
                    });
                  },
                  onDateTap: _selectDate,
                  dateLabel:
                      widget.recurringEditScope ==
                          RecurringEditScope.thisAndFuture
                      ? 'Próxima cobrança'
                      : 'Data',
                  onSubmit: _save,
                  submitLabel: 'Salvar alterações',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
