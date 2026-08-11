import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/expenses/widgets/expense_form_content.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:intl/intl.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({
    super.key,
    required this.categories,
    required this.onSave,
    this.onSaveRecurring,
  }) : assert(categories.length > 0);

  final List<ExpenseCategory> categories;
  final Future<void> Function({
    required double amount,
    required String categoryId,
    String? description,
    required DateTime occurredAt,
  })
  onSave;
  final Future<void> Function({
    required ExpenseType type,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime startDate,
    int? totalOccurrences,
  })?
  onSaveRecurring;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _occurrencesController = TextEditingController();

  late String _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isSaving = false;
  ExpenseType _expenseType = ExpenseType.single;
  bool _limitedSubscription = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categories.first.id;
    _selectedDate = DateTime.now();
    _amountController.addListener(_refreshSummary);
    _occurrencesController.addListener(_refreshSummary);
  }

  void _refreshSummary() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _occurrencesController.dispose();
    super.dispose();
  }

  String? _validateOccurrences(String? value) {
    if (_expenseType == ExpenseType.single ||
        (_expenseType == ExpenseType.subscription && !_limitedSubscription)) {
      return null;
    }
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null || count <= 0) return 'Informe uma quantidade válida';
    if (_expenseType == ExpenseType.installment && count <= 1) {
      return 'Para uma parcela, utilize o tipo Único';
    }
    if (count > 120) return 'Informe no máximo 120 meses';
    return null;
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
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: _expenseType == ExpenseType.single
          ? now
          : DateTime(now.year + 10, now.month, now.day),
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
      if (_expenseType == ExpenseType.single) {
        await widget.onSave(
          amount: amount,
          categoryId: _selectedCategoryId,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          occurredAt: _selectedDate,
        );
      } else {
        final callback = widget.onSaveRecurring;
        if (callback == null) throw StateError('Recorrência indisponível');
        await callback(
          type: _expenseType,
          amount: amount,
          categoryId: _selectedCategoryId,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          startDate: _selectedDate,
          totalOccurrences:
              _expenseType == ExpenseType.subscription && !_limitedSubscription
              ? null
              : int.parse(_occurrencesController.text),
        );
      }

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Adicionar gasto'),
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
                  'Novo gasto',
                  style: AppTypography.h2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Registre rapidamente o que você gastou.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ExpenseFormContent(
                  amountController: _amountController,
                  descriptionController: _descriptionController,
                  categories: widget.categories,
                  selectedCategoryId: _selectedCategoryId,
                  selectedDate: _selectedDate,
                  isSaving: _isSaving,
                  amountValidator: _validateAmount,
                  amountLabel: switch (_expenseType) {
                    ExpenseType.single => 'Valor do gasto',
                    ExpenseType.subscription => 'Valor mensal',
                    ExpenseType.installment => 'Valor total da compra',
                  },
                  dateLabel: switch (_expenseType) {
                    ExpenseType.single => 'Data',
                    ExpenseType.subscription => 'Primeira cobrança',
                    ExpenseType.installment => 'Data da primeira parcela',
                  },
                  afterAmount: AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    child: _ExpenseTypeSection(
                      type: _expenseType,
                      limitedSubscription: _limitedSubscription,
                      occurrencesController: _occurrencesController,
                      occurrencesValidator: _validateOccurrences,
                      onTypeChanged: (type) => setState(() {
                        _expenseType = type;
                        _occurrencesController.clear();
                      }),
                      onLimitedChanged: (limited) => setState(() {
                        _limitedSubscription = limited;
                        _occurrencesController.clear();
                      }),
                    ),
                  ),
                  beforeSubmit: _RecurringSummary(
                    type: _expenseType,
                    amountText: _amountController.text,
                    occurrenceText: _occurrencesController.text,
                    limitedSubscription: _limitedSubscription,
                    startDate: _selectedDate,
                  ),
                  onCategoryChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                  onDateTap: _selectDate,
                  onSubmit: _save,
                  submitLabel: 'Salvar gasto',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseTypeSection extends StatelessWidget {
  const _ExpenseTypeSection({
    required this.type,
    required this.limitedSubscription,
    required this.occurrencesController,
    required this.occurrencesValidator,
    required this.onTypeChanged,
    required this.onLimitedChanged,
  });

  final ExpenseType type;
  final bool limitedSubscription;
  final TextEditingController occurrencesController;
  final FormFieldValidator<String> occurrencesValidator;
  final ValueChanged<ExpenseType> onTypeChanged;
  final ValueChanged<bool> onLimitedChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = switch (type) {
      ExpenseType.single => 'Um gasto feito apenas uma vez.',
      ExpenseType.subscription => 'Uma cobrança que se repete todo mês.',
      ExpenseType.installment => 'Uma compra dividida em parcelas mensais.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tipo do gasto',
          style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in ExpenseType.values)
              ChoiceChip(
                label: Text(_typeLabel(option)),
                selected: type == option,
                onSelected: (_) => onTypeChanged(option),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (type == ExpenseType.subscription) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Duração',
            style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                label: const Text('Até cancelar'),
                selected: !limitedSubscription,
                onSelected: (_) => onLimitedChanged(false),
              ),
              ChoiceChip(
                label: const Text('Por quantidade de meses'),
                selected: limitedSubscription,
                onSelected: (_) => onLimitedChanged(true),
              ),
            ],
          ),
        ],
        if (type == ExpenseType.installment || limitedSubscription) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: occurrencesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: occurrencesValidator,
            decoration: InputDecoration(
              labelText: type == ExpenseType.installment
                  ? 'Número de parcelas'
                  : 'Quantidade de meses',
              prefixIcon: const Icon(Icons.calendar_view_month_rounded),
            ),
          ),
        ],
      ],
    );
  }

  String _typeLabel(ExpenseType value) => switch (value) {
    ExpenseType.single => 'Único',
    ExpenseType.subscription => 'Assinatura',
    ExpenseType.installment => 'Parcelado',
  };
}

class _RecurringSummary extends StatelessWidget {
  const _RecurringSummary({
    required this.type,
    required this.amountText,
    required this.occurrenceText,
    required this.limitedSubscription,
    required this.startDate,
  });

  final ExpenseType type;
  final String amountText;
  final String occurrenceText;
  final bool limitedSubscription;
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    if (type == ExpenseType.single) return const SizedBox.shrink();
    final amount = CurrencyUtils.tryParse(amountText);
    final count = int.tryParse(occurrenceText);
    if (amount == null || amount <= 0) return const SizedBox.shrink();
    final date = DateFormat('dd/MM/yyyy').format(startDate);
    final String text;
    if (type == ExpenseType.subscription) {
      text = limitedSubscription && count != null && count > 0
          ? '${CurrencyUtils.format(amount)} por mês durante $count meses, a partir de $date.'
          : '${CurrencyUtils.format(amount)} por mês, a partir de $date, até você cancelar.';
    } else {
      if (count == null || count <= 1) return const SizedBox.shrink();
      text = '$count parcelas de ${CurrencyUtils.format(amount / count)}';
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
