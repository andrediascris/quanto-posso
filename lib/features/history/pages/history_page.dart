import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/features/expenses/pages/edit_expense_page.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/cards/recent_expense_card.dart';
import 'package:quanto_posso/shared/inputs/app_text_field.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.categories,
    this.onExpenseDeleted,
  });

  final List<ExpenseCategory> categories;
  final VoidCallback? onExpenseDeleted;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryProvider>().loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.medium);
    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Consumer<HistoryProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Histórico',
                    style: AppTypography.h2.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Consulte e gerencie todos os seus gastos.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _searchController,
                    label: 'Pesquisar',
                    hint: 'Buscar pela descrição',
                    prefixIcon: Icons.search_rounded,
                    onChanged: provider.setSearchQuery,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: provider.selectedCategoryId,
                    dropdownColor: AppColors.surfaceLight,
                    iconEnabledColor: AppColors.primary,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      border: border,
                      enabledBorder: border,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        child: Text('Todas as categorias'),
                      ),
                      for (final category in widget.categories)
                        DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: provider.setCategoryFilter,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: _buildContent(context, provider)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HistoryProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.status == HistoryStatus.error) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            provider.errorMessage ?? 'Não foi possível carregar o histórico.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Tentar novamente',
            onPressed: provider.loadHistory,
          ),
        ],
      );
    }

    final expenses = provider.filteredExpenses;
    if (expenses.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum gasto encontrado.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Registre um gasto ou altere os filtros.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: ValueKey('expense_${expense.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Excluir',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) => _deleteExpense(context, expense),
          child: RecentExpenseCard(
            expense: expense,
            category: _categoryFor(expense),
            onTap: () => _editExpense(context, expense),
            onDelete: () => _deleteExpense(context, expense),
          ),
        );
      },
    );
  }

  Future<bool> _deleteExpense(BuildContext context, Expense expense) async {
    final id = expense.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir este gasto.')),
      );
      return false;
    }

    final confirmed = await _confirmDeletion(context);
    if (!confirmed || !context.mounted) return false;
    return _performDeletion(context, expense);
  }

  Future<void> _editExpense(BuildContext context, Expense expense) async {
    final categories = context.read<InitialSetupProvider>().categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma categoria dispon\u00edvel.')),
      );
      return;
    }
    final expenseProvider = context.read<ExpenseProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final budgetAlertProvider = context.read<BudgetAlertProvider>();
    final profile = context.read<InitialSetupProvider>().profile;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditExpensePage(
          expense: expense,
          categories: categories,
          onSave:
              ({
                required expense,
                required amount,
                required categoryId,
                description,
                required occurredAt,
              }) async {
                await expenseProvider.updateExpense(
                  expense: expense,
                  amount: amount,
                  categoryId: categoryId,
                  description: description,
                  occurredAt: occurredAt,
                );
                if (!mounted) return;
                await historyProvider.loadHistory();
                if (!mounted) return;
                await dashboardProvider.loadDashboard();
                if (!mounted) return;
                if (profile != null) {
                  await budgetAlertProvider.evaluateBudget(
                    monthlyIncome: profile.monthlyIncome,
                    monthlyExpenseTotal: expenseProvider.monthlyTotal,
                  );
                }
              },
        ),
      ),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto atualizado com sucesso.')),
      );
    }
  }

  Future<bool> _confirmDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text(
          'Excluir gasto?',
          style: AppTypography.h3.copyWith(color: AppColors.primary),
        ),
        content: Text(
          'Essa ação não poderá ser desfeita.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Excluir',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _performDeletion(BuildContext context, Expense expense) async {
    try {
      await context.read<HistoryProvider>().deleteExpense(expense.id!);
      if (!context.mounted) return false;
      await context.read<ExpenseProvider>().loadCurrentMonth();
      if (!context.mounted) return false;
      await context.read<DashboardProvider>().loadDashboard();
      if (!context.mounted) return false;
      final profile = context.read<InitialSetupProvider>().profile;
      if (profile != null) {
        await context.read<BudgetAlertProvider>().evaluateBudget(
          monthlyIncome: profile.monthlyIncome,
          monthlyExpenseTotal: context.read<ExpenseProvider>().monthlyTotal,
        );
        if (!context.mounted) return false;
      }
      widget.onExpenseDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto excluído com sucesso.')),
      );
      return true;
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o gasto.')),
        );
      }
      return false;
    }
  }

  ExpenseCategory _categoryFor(Expense expense) {
    for (final category in widget.categories) {
      if (category.id == expense.categoryId) {
        return category;
      }
    }
    return ExpenseCategory(
      id: expense.categoryId,
      name: 'Categoria',
      iconCodePoint: Icons.category_rounded.codePoint,
      iconFontFamily: Icons.category_rounded.fontFamily ?? 'MaterialIcons',
      colorValue: AppColors.primary.toARGB32(),
      isDefault: false,
      createdAt: expense.createdAt,
    );
  }
}
