import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/features/recurring/pages/recurring_plan_details_page.dart';
import 'package:quanto_posso/features/recurring/widgets/recurring_plan_card.dart';
import 'package:quanto_posso/features/recurring/widgets/recurring_summary_card.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';

class RecurringExpensesPage extends StatefulWidget {
  const RecurringExpensesPage({super.key, required this.onAddExpense});
  final Future<void> Function() onAddExpense;

  @override
  State<RecurringExpensesPage> createState() => _RecurringExpensesPageState();
}

class _RecurringExpensesPageState extends State<RecurringExpensesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecurringExpenseProvider>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<InitialSetupProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Recorrências')),
      body: SafeArea(
        child: Consumer<RecurringExpenseProvider>(
          builder: (context, provider, child) => ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            children: [
              Text(
                'Gerencie suas assinaturas e compras parceladas.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RecurringSummaryCard(
                monthlyCommitment: provider.totalMonthlyCommitment,
                subscriptions: provider.activeSubscriptionCount,
                installments: provider.activeInstallmentCount,
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in RecurringPlanFilter.values) ...[
                      FilterChip(
                        label: Text(_filterLabel(filter)),
                        selected: provider.filter == filter,
                        onSelected: (_) => provider.setFilter(filter),
                      ),
                      if (filter != RecurringPlanFilter.values.last)
                        const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (provider.isLoading) const LinearProgressIndicator(),
              if (provider.status == RecurringExpenseStatus.error)
                _MessageState(
                  icon: Icons.error_outline_rounded,
                  title: 'Não foi possível carregar suas recorrências.',
                  actionLabel: 'Tentar novamente',
                  onAction: provider.reload,
                )
              else if (!provider.isLoading && provider.plans.isEmpty)
                _MessageState(
                  icon: Icons.autorenew_rounded,
                  title: 'Nenhuma recorrência cadastrada.',
                  description:
                      'Assinaturas e compras parceladas aparecerão aqui.',
                  actionLabel: 'Adicionar gasto',
                  onAction: widget.onAddExpense,
                )
              else if (!provider.isLoading && provider.filteredPlans.isEmpty)
                const _MessageState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'Nenhum resultado neste filtro.',
                  description:
                      'Selecione outro filtro para visualizar suas recorrências.',
                )
              else
                for (final plan in provider.filteredPlans) ...[
                  RecurringPlanCard(
                    plan: plan,
                    category: _categoryFor(categories, plan.categoryId),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecurringPlanDetailsPage(
                          planId: plan.id!,
                          categories: categories,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }

  ExpenseCategory _categoryFor(List<ExpenseCategory> categories, String id) =>
      categories.firstWhere((category) => category.id == id);

  String _filterLabel(RecurringPlanFilter filter) => switch (filter) {
    RecurringPlanFilter.all => 'Todos',
    RecurringPlanFilter.subscriptions => 'Assinaturas',
    RecurringPlanFilter.installments => 'Parcelamentos',
    RecurringPlanFilter.completed => 'Concluídos',
  };
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}
