import 'package:flutter/material.dart';
import 'package:quanto_posso/core/utils/category_icon_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/dashboard_insight.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/charts/category_pie_chart.dart';
import 'package:quanto_posso/shared/charts/monthly_expense_line_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.profile,
    required this.categories,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DashboardProvider>();
      provider
        ..setFinancialContext(
          monthlyIncome: widget.profile.monthlyIncome,
          categories: widget.categories,
        )
        ..loadDashboard();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.categories != widget.categories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DashboardProvider>().setFinancialContext(
          monthlyIncome: widget.profile.monthlyIncome,
          categories: widget.categories,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            final dashboardReady =
                !provider.isLoading && provider.status == DashboardStatus.ready;
            return RefreshIndicator(
              onRefresh: provider.loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.md,
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _DashboardHeader(),
                          const SizedBox(height: AppSpacing.md),
                          _MonthSelector(provider: provider),
                          if (dashboardReady) ...[
                            const SizedBox(height: AppSpacing.md),
                            _TopSummaryCards(
                              income: widget.profile.monthlyIncome,
                              spent: provider.currentMonthTotal,
                              remaining:
                                  widget.profile.monthlyIncome -
                                  provider.currentMonthTotal,
                              incomePercentage: provider.incomeUsagePercentage,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLowest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.card),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                      ),
                      child: _buildState(provider),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildState(DashboardProvider provider) {
    if (provider.isLoading || provider.status == DashboardStatus.initial) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (provider.status == DashboardStatus.error) {
      return Column(
        children: [
          Text(
            provider.errorMessage ?? 'Não foi possível carregar o dashboard.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Tentar novamente',
            onPressed: provider.loadDashboard,
          ),
        ],
      );
    }
    return _DashboardContent(categories: widget.categories, provider: provider);
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTypography.h2.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Visão geral das suas finanças',
                style: AppTypography.body.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Icon(Icons.calendar_month_outlined, color: AppColors.textLight),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.provider});

  final DashboardProvider provider;

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Selecionar mês. ${_monthLabel(provider.selectedMonth)}',
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: () => _showMonthControls(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: AppColors.textLight),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _monthLabel(provider.selectedMonth),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      return 'Este mês';
    }
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  Future<void> _showMonthControls(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecionar mês',
                style: AppTypography.h3.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: () async {
                      await provider.previousMonth();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(provider.selectedMonth),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: provider.canGoToNextMonth
                        ? () async {
                            await provider.nextMonth();
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          }
                        : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: provider.canGoToNextMonth
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.disabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EvolutionMode { daily, monthly }

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({required this.categories, required this.provider});

  final List<ExpenseCategory> categories;
  final DashboardProvider provider;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  _EvolutionMode _evolutionMode = _EvolutionMode.daily;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final categories = widget.categories;
    final rankedCategories = provider.rankedCategoryTotals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSectionCard(
          title: 'Gastos por categoria',
          actionLabel: 'Ver todas',
          onAction: () => _showCategoryList(
            context,
            title: 'Todas as categorias',
            showPosition: false,
          ),
          child: CategoryPieChart(
            totalsByCategory: provider.totalsByCategory,
            categories: categories,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DashboardSectionCard(
          title: 'Evolução dos gastos',
          trailing: _PeriodSelector(
            mode: _evolutionMode,
            onSelected: (mode) => setState(() => _evolutionMode = mode),
          ),
          child: _evolutionMode == _EvolutionMode.daily
              ? MonthlyExpenseLineChart(
                  dailyTotals: provider.dailyTotals,
                  month: provider.selectedMonth,
                )
              : SixMonthExpenseLineChart(monthlyTotals: provider.lastSixMonths),
        ),
        const SizedBox(height: AppSpacing.md),
        _ComparisonAndRanking(
          comparison: provider.comparisonPercentage,
          rankedCategories: rankedCategories.take(3).toList(growable: false),
          categories: categories,
          onViewRanking: () => _showCategoryList(
            context,
            title: 'Ranking por categoria',
            showPosition: true,
          ),
        ),
        if (provider.insights.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _MonthlyInsightCard(insight: provider.insights.first),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          const _MonthlyInsightCard(),
        ],
      ],
    );
  }

  Future<void> _showCategoryList(
    BuildContext context, {
    required String title,
    required bool showPosition,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) => _CategoryTotalsSheet(
        title: title,
        entries: widget.provider.rankedCategoryTotals,
        categories: widget.categories,
        total: widget.provider.currentMonthTotal,
        showPosition: showPosition,
      ),
    );
  }
}

class _TopSummaryCards extends StatelessWidget {
  const _TopSummaryCards({
    required this.income,
    required this.spent,
    required this.remaining,
    required this.incomePercentage,
  });

  final double income;
  final double spent;
  final double remaining;
  final double incomePercentage;

  @override
  Widget build(BuildContext context) {
    final percentage = NumberFormat('0.0', 'pt_BR').format(incomePercentage);
    final availablePercentage = NumberFormat(
      '0.0',
      'pt_BR',
    ).format((100 - incomePercentage).clamp(0, 100));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Renda do mês',
              value: CurrencyUtils.format(income),
              helper: '100% da renda',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              label: 'Total gasto',
              value: CurrencyUtils.format(spent),
              helper: '$percentage% da renda',
              icon: Icons.payments_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              label: 'Saldo restante',
              value: CurrencyUtils.format(remaining < 0 ? 0 : remaining),
              helper: remaining < 0
                  ? 'Limite ultrapassado'
                  : '$availablePercentage% disponível',
              icon: Icons.savings_outlined,
              color: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              color: AppColors.textLight.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Icon(icon, color: color, size: AppSpacing.md),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.trailing,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final Widget? trailing;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                Semantics(
                  button: true,
                  label: actionLabel,
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: AppTypography.small.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ?trailing,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.mode, required this.onSelected});

  final _EvolutionMode mode;
  final ValueChanged<_EvolutionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_EvolutionMode>(
      tooltip: 'Selecionar visualização da evolução',
      initialValue: mode,
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _EvolutionMode.daily, child: Text('Diário')),
        PopupMenuItem(value: _EvolutionMode.monthly, child: Text('Mensal')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mode == _EvolutionMode.daily ? 'Diário' : 'Mensal',
              style: AppTypography.small.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: AppSpacing.md,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonAndRanking extends StatelessWidget {
  const _ComparisonAndRanking({
    required this.comparison,
    required this.rankedCategories,
    required this.categories,
    required this.onViewRanking,
  });

  final double comparison;
  final List<MapEntry<String, double>> rankedCategories;
  final List<ExpenseCategory> categories;
  final VoidCallback onViewRanking;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _ComparisonCard(comparison: comparison)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _RankingCard(
              entries: rankedCategories,
              categories: categories,
              onViewRanking: onViewRanking,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final double comparison;

  @override
  Widget build(BuildContext context) {
    final decreased = comparison < 0;
    final color = decreased
        ? AppColors.success
        : comparison > 0
        ? AppColors.warning
        : Theme.of(context).colorScheme.primary;
    final icon = decreased
        ? Icons.trending_down_rounded
        : comparison > 0
        ? Icons.trending_up_rounded
        : Icons.trending_flat_rounded;
    final formatted = NumberFormat('0.0', 'pt_BR').format(comparison.abs());
    final explanation = comparison == 0
        ? 'Seus gastos não variaram em relação ao mês passado.'
        : 'Você gastou $formatted% ${decreased ? 'menos' : 'mais'} que no mês passado.';

    return _BaseCard(
      padding: AppSpacing.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Comparação com mês anterior',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(icon, size: AppSpacing.md, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Icon(icon, size: AppSpacing.md, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comparison > 0
                          ? '+'
                          : comparison < 0
                          ? '-'
                          : ''}$formatted%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(color: color),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      explanation,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.small.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.entries,
    required this.categories,
    required this.onViewRanking,
  });

  final List<MapEntry<String, double>> entries;
  final List<ExpenseCategory> categories;
  final VoidCallback onViewRanking;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      padding: AppSpacing.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Maiores gastos do mês',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onViewRanking,
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver ranking',
                      style: AppTypography.small.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: AppSpacing.xs,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: AppSpacing.sm,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < 3; index++) ...[
            _RankingItem(
              position: index + 1,
              entry: index < entries.length ? entries[index] : null,
              category: index < entries.length
                  ? _categoryFor(entries[index].key)
                  : null,
            ),
            if (index < 2) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  ExpenseCategory? _categoryFor(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({
    required this.position,
    required this.entry,
    required this.category,
  });

  final int position;
  final MapEntry<String, double>? entry;
  final ExpenseCategory? category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final icon = category == null
        ? Icons.category_outlined
        : CategoryIconUtils.resolve(category!.iconCodePoint);
    return Row(
      children: [
        Text(
          '$position',
          style: AppTypography.small.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          child: Icon(icon, size: AppSpacing.md, color: color),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            category?.name ?? 'Sem dados',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyUtils.format(entry?.value ?? 0),
              maxLines: 1,
              style: AppTypography.small.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(ExpenseCategory? category) {
    final value = category?.colorValue;
    if (value == null || value < 0 || value > 0xFFFFFFFF) {
      return AppColors.primary;
    }
    return Color(value);
  }
}

class _CategoryTotalsSheet extends StatelessWidget {
  const _CategoryTotalsSheet({
    required this.title,
    required this.entries,
    required this.categories,
    required this.total,
    required this.showPosition,
  });

  final String title;
  final List<MapEntry<String, double>> entries;
  final List<ExpenseCategory> categories;
  final double total;
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text(
              'Nenhum gasto no período selecionado.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              _CategoryTotalRow(
                position: showPosition ? index + 1 : null,
                entry: entries[index],
                category: _categoryFor(entries[index].key),
                total: total,
              ),
              if (index < entries.length - 1)
                const Divider(height: AppSpacing.lg),
            ],
        ],
      ),
    );
  }

  ExpenseCategory? _categoryFor(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class _CategoryTotalRow extends StatelessWidget {
  const _CategoryTotalRow({
    required this.position,
    required this.entry,
    required this.category,
    required this.total,
  });

  final int? position;
  final MapEntry<String, double> entry;
  final ExpenseCategory? category;
  final double total;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final percentage = total > 0 ? entry.value / total * 100 : 0.0;
    final positionLabel = position == null ? '' : '$positionº lugar, ';
    return Semantics(
      label:
          '$positionLabel${category?.name ?? 'Outros'}, '
          '${CurrencyUtils.format(entry.value)}, '
          '${NumberFormat('0.0', 'pt_BR').format(percentage)} por cento',
      child: Row(
        children: [
          if (position != null) ...[
            SizedBox(
              width: AppSpacing.xl,
              child: Text(
                '$positionº',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(_icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              category?.name ?? 'Outros',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.format(entry.value),
                maxLines: 1,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${NumberFormat('0.0', 'pt_BR').format(percentage)}%',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _color {
    final value = category?.colorValue;
    return value == null || value < 0 || value > 0xFFFFFFFF
        ? AppColors.primary
        : Color(value);
  }

  IconData get _icon => category == null
      ? Icons.category_outlined
      : CategoryIconUtils.resolve(category!.iconCodePoint);
}

class _MonthlyInsightCard extends StatelessWidget {
  const _MonthlyInsightCard({this.insight});

  final DashboardInsight? insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight do mês',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight?.title ?? 'Continue acompanhando seus gastos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight?.description ??
                      'Seus próximos registros ajudarão a revelar novas tendências.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.auto_awesome_rounded, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child, this.padding = AppSpacing.cardPadding});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: child,
    );
  }
}
