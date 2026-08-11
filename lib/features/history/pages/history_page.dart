import 'package:flutter/material.dart';
import 'package:quanto_posso/core/utils/category_icon_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/features/expenses/widgets/recurring_expense_badge.dart';
import 'package:quanto_posso/features/expenses/pages/edit_expense_page.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
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
        final provider = context.read<HistoryProvider>();
        _searchController.text = provider.searchQuery;
        provider
          ..setCategories(widget.categories)
          ..loadHistory();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HistoryProvider>().setCategories(widget.categories);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  _HistoryHeader(onOpenFilters: () => _showFilters(context)),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    label: 'Pesquisar',
                    hint: 'Buscar por descrição',
                    prefixIcon: Icons.search_rounded,
                    onChanged: provider.setSearchQuery,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickFilters(
                    period: _quickSelectedPeriodLabel(provider),
                    category: _categoryFilterLabel(provider),
                    sort: _sortLabel(provider.sort),
                    periodActive: provider.selectedPeriod != HistoryPeriod.all,
                    categoryActive: provider.selectedCategoryId != null,
                    sortActive: provider.sort != HistorySort.newest,
                    hasActiveFilters: provider.hasActiveFilters,
                    onSelectPeriod: () => _showQuickPeriod(context, provider),
                    onSelectCategory: () =>
                        _showQuickCategory(context, provider),
                    onSelectSort: () => _showQuickSort(context, provider),
                    onClear: () => _clearFilters(provider),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HistorySummaryCard(
                    resultCount: provider.filteredExpenses.length,
                    total: provider.filteredTotal,
                    hasActiveFilters: provider.hasActiveFilters,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: _buildContent(context, provider)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final provider = context.read<HistoryProvider>();
    final minimumController = TextEditingController(
      text: provider.minimumValue == null
          ? ''
          : CurrencyUtils.formatForInput(provider.minimumValue!),
    );
    final maximumController = TextEditingController(
      text: provider.maximumValue == null
          ? ''
          : CurrencyUtils.formatForInput(provider.maximumValue!),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => Consumer<HistoryProvider>(
        builder: (context, currentProvider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtros avançados',
                          style: AppTypography.h3.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar filtros',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterLabel(label: 'Período'),
                  const SizedBox(height: AppSpacing.xs),
                  _AppDropdown<HistoryPeriod>(
                    value: currentProvider.selectedPeriod,
                    items: HistoryPeriod.values
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(_periodOptionLabel(period)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (period) {
                      if (period == null) return;
                      if (period == HistoryPeriod.custom) {
                        _selectCustomPeriod(sheetContext, currentProvider);
                      } else {
                        currentProvider.setPeriod(period);
                      }
                    },
                  ),
                  if (currentProvider.selectedPeriod ==
                      HistoryPeriod.custom) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _periodLabel(currentProvider),
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _FilterLabel(label: 'Categoria'),
                  const SizedBox(height: AppSpacing.xs),
                  _AppDropdown<String?>(
                    value: currentProvider.selectedCategoryId,
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
                    onChanged: currentProvider.setCategoryFilter,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterLabel(label: 'Faixa de valores'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: minimumController,
                          label: 'Valor mínimo',
                          prefixText: 'R\$ ',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: maximumController,
                          label: 'Valor máximo',
                          prefixText: 'R\$ ',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterLabel(label: 'Ordenar por'),
                  const SizedBox(height: AppSpacing.xs),
                  _AppDropdown<HistorySort>(
                    value: currentProvider.sort,
                    items: HistorySort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(_sortLabel(sort)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (sort) {
                      if (sort != null) currentProvider.setSort(sort);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Aplicar filtros',
                    icon: Icons.check_rounded,
                    onPressed: () => _applyValueRange(
                      sheetContext,
                      currentProvider,
                      minimumController,
                      maximumController,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      minimumController.clear();
                      maximumController.clear();
                      _clearFilters(currentProvider);
                    },
                    child: Text(
                      'Limpar filtros',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    minimumController.dispose();
    maximumController.dispose();
  }

  Future<void> _showQuickPeriod(
    BuildContext context,
    HistoryProvider provider,
  ) async {
    final period = await _showQuickOptions<HistoryPeriod>(
      context: context,
      title: 'Selecionar período',
      selected: provider.selectedPeriod,
      options: HistoryPeriod.values,
      labelFor: _quickPeriodLabel,
    );
    if (period == null || !context.mounted) return;
    if (period == HistoryPeriod.custom) {
      await _selectCustomPeriod(context, provider);
    } else {
      provider.setPeriod(period);
    }
  }

  Future<void> _showQuickCategory(
    BuildContext context,
    HistoryProvider provider,
  ) async {
    const allCategories = '__all_categories__';
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _QuickSheetHeader(title: 'Selecionar categoria'),
            ListTile(
              title: const Text('Todas categorias'),
              trailing: provider.selectedCategoryId == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(allCategories),
            ),
            for (final category in widget.categories)
              ListTile(
                leading: _QuickCategoryIcon(category: category),
                title: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: provider.selectedCategoryId == category.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(category.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    provider.setCategoryFilter(selected == allCategories ? null : selected);
  }

  Future<void> _showQuickSort(
    BuildContext context,
    HistoryProvider provider,
  ) async {
    final sort = await _showQuickOptions<HistorySort>(
      context: context,
      title: 'Alterar ordenação',
      selected: provider.sort,
      options: HistorySort.values,
      labelFor: _sortLabel,
    );
    if (sort != null) provider.setSort(sort);
  }

  Future<T?> _showQuickOptions<T>({
    required BuildContext context,
    required String title,
    required T selected,
    required List<T> options,
    required String Function(T option) labelFor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _QuickSheetHeader(title: title),
            for (final option in options)
              ListTile(
                title: Text(
                  labelFor(option),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: selected == option
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomPeriod(
    BuildContext context,
    HistoryProvider provider,
  ) async {
    final now = DateTime.now();
    final initialStart = provider.customPeriodStart ?? now;
    final initialEnd = provider.customPeriodEnd ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Selecione o período',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
            secondary: AppColors.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      provider.setCustomPeriod(start: range.start, end: range.end);
    }
  }

  void _applyValueRange(
    BuildContext context,
    HistoryProvider provider,
    TextEditingController minimumController,
    TextEditingController maximumController,
  ) {
    final minimumText = minimumController.text.trim();
    final maximumText = maximumController.text.trim();
    final minimum = minimumText.isEmpty
        ? null
        : CurrencyUtils.tryParse(minimumText);
    final maximum = maximumText.isEmpty
        ? null
        : CurrencyUtils.tryParse(maximumText);
    if ((minimumText.isNotEmpty && minimum == null) ||
        (maximumText.isNotEmpty && maximum == null) ||
        (minimum != null && minimum < 0) ||
        (maximum != null && maximum < 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe valores válidos.')));
      return;
    }
    if (minimum != null && maximum != null && minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O valor mínimo não pode superar o máximo.'),
        ),
      );
      return;
    }
    provider.setValueRange(minimum: minimum, maximum: maximum);
    Navigator.of(context).pop();
  }

  void _clearFilters(HistoryProvider provider) {
    _searchController.clear();
    provider.clearFilters();
  }

  String _periodLabel(HistoryProvider provider) {
    return switch (provider.selectedPeriod) {
      HistoryPeriod.all => 'Todo o período',
      HistoryPeriod.today => 'Hoje',
      HistoryPeriod.lastSevenDays => 'Esta semana',
      HistoryPeriod.thisMonth => 'Este mês',
      HistoryPeriod.lastMonth => 'Mês passado',
      HistoryPeriod.custom =>
        provider.customPeriodStart == null || provider.customPeriodEnd == null
            ? 'Personalizado'
            : '${_formatDate(provider.customPeriodStart!)} a '
                  '${_formatDate(provider.customPeriodEnd!)}',
    };
  }

  String _quickSelectedPeriodLabel(HistoryProvider provider) =>
      provider.selectedPeriod == HistoryPeriod.custom
      ? 'Personalizado'
      : _periodLabel(provider);

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _periodOptionLabel(HistoryPeriod period) => switch (period) {
    HistoryPeriod.all => 'Todo o período',
    HistoryPeriod.today => 'Hoje',
    HistoryPeriod.lastSevenDays => 'Esta semana',
    HistoryPeriod.thisMonth => 'Este mês',
    HistoryPeriod.lastMonth => 'Mês passado',
    HistoryPeriod.custom => 'Personalizado',
  };

  String _quickPeriodLabel(HistoryPeriod period) => switch (period) {
    HistoryPeriod.custom => 'Período personalizado',
    _ => _periodOptionLabel(period),
  };

  String _categoryFilterLabel(HistoryProvider provider) {
    final categoryId = provider.selectedCategoryId;
    if (categoryId == null) return 'Todas categorias';
    for (final category in widget.categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Categoria selecionada';
  }

  String _sortLabel(HistorySort sort) => switch (sort) {
    HistorySort.newest => 'Mais recentes',
    HistorySort.oldest => 'Mais antigos',
    HistorySort.highestValue => 'Maior valor',
    HistorySort.lowestValue => 'Menor valor',
    HistorySort.categoryAscending => 'Categoria A-Z',
    HistorySort.categoryDescending => 'Categoria Z-A',
  };

  Widget _buildContent(BuildContext context, HistoryProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (provider.status == HistoryStatus.error) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  provider.errorMessage ??
                      'Não foi possível carregar o histórico.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Tentar novamente',
                  onPressed: provider.loadHistory,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final expenses = provider.filteredExpenses;
    if (expenses.isEmpty) {
      return _HistoryEmptyState(
        hasActiveFilters: provider.hasActiveFilters,
        onClearFilters: () => _clearFilters(provider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final showDateHeader =
            index == 0 ||
            !_isSameDay(expense.occurredAt, expenses[index - 1].occurredAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              Text(
                _dateGroupLabel(expense.occurredAt),
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Semantics(
              label: 'Deslize para excluir o gasto',
              child: Dismissible(
                key: ValueKey('expense_${expense.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textLight,
                  ),
                ),
                confirmDismiss: (direction) => _deleteExpense(context, expense),
                child: _HistoryExpenseCard(
                  expense: expense,
                  category: _categoryFor(expense),
                  onEdit: () => _editExpense(context, expense),
                  onDelete: () => _deleteExpense(context, expense),
                ),
              ),
            ),
            if (index < expenses.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _dateGroupLabel(DateTime date) {
    const monthNames = [
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Hoje';
    if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
    final formattedDay = date.day.toString().padLeft(2, '0');
    return '$formattedDay de ${monthNames[date.month - 1]}';
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
    final scope = expense.recurringPlanId == null
        ? RecurringEditScope.onlyThis
        : await showRecurringEditScopeSheet(context);
    if (scope == null || !context.mounted) return;
    final nextBillingDate = scope == RecurringEditScope.thisAndFuture
        ? await expenseProvider.getNextBillingDate(expense.recurringPlanId!)
        : null;
    if (scope == RecurringEditScope.thisAndFuture && nextBillingDate == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorrência não encontrada.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final historyProvider = context.read<HistoryProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final budgetAlertProvider = context.read<BudgetAlertProvider>();
    final profile = context.read<InitialSetupProvider>().profile;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditExpensePage(
          expense: expense,
          categories: categories,
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
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text(
          'Excluir gasto?',
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Text(
          'Essa ação não poderá ser desfeita.',
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico',
                style: AppTypography.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Consulte e gerencie seus gastos.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Abrir filtros avançados',
          onPressed: onOpenFilters,
          icon: Icon(
            Icons.tune_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.period,
    required this.category,
    required this.sort,
    required this.periodActive,
    required this.categoryActive,
    required this.sortActive,
    required this.hasActiveFilters,
    required this.onSelectPeriod,
    required this.onSelectCategory,
    required this.onSelectSort,
    required this.onClear,
  });

  final String period;
  final String category;
  final String sort;
  final bool periodActive;
  final bool categoryActive;
  final bool sortActive;
  final bool hasActiveFilters;
  final VoidCallback onSelectPeriod;
  final VoidCallback onSelectCategory;
  final VoidCallback onSelectSort;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HistoryFilterChip(
                  label: period,
                  selected: periodActive,
                  semanticLabel: 'Selecionar período',
                  onSelected: onSelectPeriod,
                ),
                const SizedBox(width: AppSpacing.xs),
                _HistoryFilterChip(
                  label: category,
                  selected: categoryActive,
                  semanticLabel: 'Selecionar categoria',
                  onSelected: onSelectCategory,
                ),
                const SizedBox(width: AppSpacing.xs),
                _HistoryFilterChip(
                  label: sort,
                  selected: sortActive,
                  semanticLabel: 'Alterar ordenação',
                  onSelected: onSelectSort,
                ),
              ],
            ),
          ),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Limpar',
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.semanticLabel,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$semanticLabel. Valor atual: $label',
      child: Tooltip(
        message: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.buttonHeight * 4,
          ),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.small,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
            selected: selected,
            onSelected: (_) => onSelected(),
            selectedColor: AppColors.accent.withValues(alpha: 0.18),
            backgroundColor: Theme.of(context).colorScheme.surface,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSheetHeader extends StatelessWidget {
  const _QuickSheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenHorizontal,
      vertical: AppSpacing.sm,
    ),
    child: Text(
      title,
      style: AppTypography.h3.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _QuickCategoryIcon extends StatelessWidget {
  const _QuickCategoryIcon({required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
        ? Color(category.colorValue)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Icon(
        CategoryIconUtils.resolve(category.iconCodePoint),
        color: color,
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.resultCount,
    required this.total,
    required this.hasActiveFilters,
  });

  final int resultCount;
  final double total;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveFilters
                      ? '$resultCount gastos encontrados'
                      : '$resultCount gastos registrados',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Total filtrado',
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyUtils.format(total),
                    maxLines: 1,
                    style: AppTypography.moneyMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        Icon(
          hasActiveFilters
              ? Icons.search_off_rounded
              : Icons.receipt_long_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasActiveFilters
              ? 'Nenhum gasto encontrado.'
              : 'Nenhum gasto registrado.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasActiveFilters
              ? 'Altere ou limpe os filtros para ver outros resultados.'
              : 'Adicione um gasto para começar seu histórico.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: onClearFilters,
              child: Text(
                'Limpar filtros',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryExpenseCard extends StatelessWidget {
  const _HistoryExpenseCard({
    required this.expense,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final ExpenseCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
        ? Color(category.colorValue)
        : Theme.of(context).colorScheme.primary;
    final icon = CategoryIconUtils.resolve(category.iconCodePoint);
    final description = expense.description?.trim();
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onEdit,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useCompactTrailing = constraints.maxWidth < 400;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Icon(icon, color: categoryColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (expense.recurringPlanId != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          RecurringExpenseBadge(expense: expense),
                        ],
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          DateFormat('HH:mm').format(expense.occurredAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.small.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _HistoryExpenseTrailing(
                    amount: expense.amount,
                    compact: useCompactTrailing,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryExpenseTrailing extends StatelessWidget {
  const _HistoryExpenseTrailing({
    required this.amount,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });

  final double amount;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amountWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        '- ${CurrencyUtils.format(amount)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar gasto',
          onPressed: onEdit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xl,
            minHeight: AppSpacing.xl,
          ),
          visualDensity: VisualDensity.compact,
          color: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Excluir gasto',
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xl,
            minHeight: AppSpacing.xl,
          ),
          visualDensity: VisualDensity.compact,
          color: AppColors.error,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: AppSpacing.buttonHeight * 2, child: amountWidget),
          const SizedBox(height: AppSpacing.xxs),
          actions,
        ],
      );
    }
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: amountWidget),
          const SizedBox(width: AppSpacing.xs),
          actions,
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _AppDropdown<T> extends StatelessWidget {
  const _AppDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      style: AppTypography.body.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: border,
        enabledBorder: border,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
