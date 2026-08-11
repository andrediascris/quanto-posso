import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/expenses/pages/edit_expense_page.dart';
import 'package:quanto_posso/features/recurring/widgets/recurring_status_chip.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/expense_type.dart';
import 'package:quanto_posso/models/recurring_expense_plan.dart';
import 'package:quanto_posso/models/recurring_plan_status.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

class RecurringPlanDetailsPage extends StatefulWidget {
  const RecurringPlanDetailsPage({
    super.key,
    required this.planId,
    required this.categories,
  });
  final int planId;
  final List<ExpenseCategory> categories;

  @override
  State<RecurringPlanDetailsPage> createState() =>
      _RecurringPlanDetailsPageState();
}

class _RecurringPlanDetailsPageState extends State<RecurringPlanDetailsPage> {
  List<Expense> _expenses = const [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final expenses = await context
        .read<RecurringExpenseProvider>()
        .getPlanExpenses(widget.planId);
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _loadingHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringExpenseProvider>();
    final plan = provider.plans.firstWhere((item) => item.id == widget.planId);
    final category = widget.categories.firstWhere(
      (item) => item.id == plan.categoryId,
    );
    final next = RecurringExpenseProvider.nextOccurrence(plan);
    final installment = plan.type == ExpenseType.installment;
    final nextNumber = plan.totalOccurrences == null
        ? plan.generatedOccurrences + 1
        : (plan.generatedOccurrences < plan.totalOccurrences!
              ? plan.generatedOccurrences + 1
              : plan.totalOccurrences!);
    final monthlyAmount = installment
        ? RecurringExpenseRepository.occurrenceAmount(plan, nextNumber)
        : plan.amount;
    final remaining = plan.totalOccurrences == null
        ? null
        : plan.totalOccurrences! - plan.generatedOccurrences;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da recorrência')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          children: [
            Text(
              plan.description?.trim().isNotEmpty == true
                  ? plan.description!.trim()
                  : category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RecurringStatusChip(status: plan.status, type: plan.type),
            const SizedBox(height: AppSpacing.lg),
            _DetailsCard(
              rows: [
                ('Categoria', category.name),
                ('Tipo', installment ? 'Parcelamento' : 'Assinatura'),
                (
                  installment ? 'Valor total' : 'Valor mensal',
                  CurrencyUtils.format(plan.amount),
                ),
                if (installment)
                  (
                    'Valor da próxima parcela',
                    CurrencyUtils.format(monthlyAmount),
                  ),
                (
                  'Data inicial',
                  DateFormat('dd/MM/yyyy').format(plan.startDate),
                ),
                (
                  'Próxima cobrança',
                  next == null
                      ? 'Nenhuma'
                      : DateFormat('dd/MM/yyyy').format(next),
                ),
                ('Quantidade gerada', '${plan.generatedOccurrences}'),
                if (plan.totalOccurrences != null)
                  ('Quantidade total', '${plan.totalOccurrences}'),
                if (remaining != null) ('Restantes', '$remaining'),
                if (!installment)
                  (
                    'Duração',
                    plan.totalOccurrences == null
                        ? 'Até cancelar'
                        : '${plan.totalOccurrences} meses',
                  ),
              ],
            ),
            if (plan.status == RecurringPlanStatus.active) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => _confirmCancellation(plan),
                icon: const Icon(Icons.block_rounded),
                label: Text(
                  installment ? 'Encerrar parcelamento' : 'Cancelar assinatura',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Histórico vinculado', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            if (_loadingHistory)
              const LinearProgressIndicator()
            else if (_expenses.isEmpty)
              Text(
                'Nenhum lançamento registrado.',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final expense in _expenses) ...[
                _OccurrenceTile(
                  expense: expense,
                  onTap: () => _editExpense(expense),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancellation(RecurringExpensePlan plan) async {
    final subscription = plan.type == ExpenseType.subscription;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          subscription ? 'Cancelar assinatura?' : 'Encerrar parcelamento?',
        ),
        content: Text(
          subscription
              ? 'As cobranças futuras não serão mais geradas. Os lançamentos já registrados serão mantidos.'
              : 'As parcelas futuras deixarão de ser geradas. As parcelas já registradas serão mantidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              subscription ? 'Cancelar assinatura' : 'Encerrar parcelamento',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<RecurringExpenseProvider>().cancelPlan(plan.id!);
  }

  Future<void> _editExpense(Expense expense) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final scope = await showRecurringEditScopeSheet(context);
    if (scope == null || !mounted) return;
    final nextBillingDate = scope == RecurringEditScope.thisAndFuture
        ? await expenseProvider.getNextBillingDate(expense.recurringPlanId!)
        : null;
    if (!mounted) return;
    if (scope == RecurringEditScope.thisAndFuture && nextBillingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrência não encontrada.')),
      );
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditExpensePage(
          expense: expense,
          categories: widget.categories,
          recurringEditScope: scope,
          nextBillingDate: nextBillingDate,
          onSave:
              ({
                required expense,
                required amount,
                required categoryId,
                description,
                required occurredAt,
              }) async {
                if (scope == RecurringEditScope.thisAndFuture) {
                  await expenseProvider.updateRecurringExpenseAndFuture(
                    expense: expense,
                    amount: amount,
                    categoryId: categoryId,
                    description: description,
                    nextBillingDate: occurredAt,
                  );
                } else {
                  await expenseProvider.updateExpense(
                    expense: expense,
                    amount: amount,
                    categoryId: categoryId,
                    description: description,
                    occurredAt: occurredAt,
                  );
                }
                if (!mounted) return;
                await context.read<HistoryProvider>().loadHistory();
                if (!mounted) return;
                await context.read<DashboardProvider>().loadDashboard();
              },
        ),
      ),
    );
    if (mounted) await _loadHistory();
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(row.$1, style: AppTypography.caption)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  row.$2,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
          if (row != rows.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ),
  );
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.expense, required this.onTap});
  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    onTap: onTap,
    title: Text(
      expense.recurringType == ExpenseType.installment
          ? 'Parcela ${expense.occurrenceNumber} de ${expense.occurrenceTotal}'
          : 'Assinatura — ${_monthLabel(expense.occurredAt)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.occurredAt)),
    trailing: Text(CurrencyUtils.format(expense.amount)),
  );

  String _monthLabel(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${months[date.month - 1]} de ${date.year}';
  }
}
