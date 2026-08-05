import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/cards/dashboard_metric_card.dart';
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
      if (mounted) {
        context.read<DashboardProvider>().loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Entenda como seus gastos estão distribuídos.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MonthSelector(provider: provider),
                    const SizedBox(height: AppSpacing.xl),
                    _buildState(provider),
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
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Tentar novamente',
            onPressed: provider.loadDashboard,
          ),
        ],
      );
    }

    return _DashboardContent(
      profile: widget.profile,
      categories: widget.categories,
      provider: provider,
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.provider});

  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    const monthNames = [
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
    final year = DateFormat('yyyy').format(provider.selectedMonth);
    final label = '${monthNames[provider.selectedMonth.month - 1]} de $year';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: 'Mês anterior',
          child: IconButton(
            tooltip: 'Mês anterior',
            onPressed: provider.previousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ),
        Semantics(
          button: true,
          label: 'Próximo mês',
          enabled: provider.canGoToNextMonth,
          child: IconButton(
            tooltip: 'Próximo mês',
            onPressed: provider.canGoToNextMonth ? provider.nextMonth : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: provider.canGoToNextMonth
                  ? AppColors.primary
                  : AppColors.disabled,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.profile,
    required this.categories,
    required this.provider,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;
  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    final remaining = profile.monthlyIncome - provider.currentMonthTotal;
    final comparison = provider.comparisonPercentage;
    final comparisonIcon = comparison > 0
        ? Icons.trending_up_rounded
        : comparison < 0
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final comparisonColor = comparison > 0
        ? AppColors.error
        : comparison < 0
        ? AppColors.success
        : AppColors.textSecondary;
    final comparisonHelper = comparison > 0
        ? 'Você gastou mais'
        : comparison < 0
        ? 'Você gastou menos'
        : 'Sem variação';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: width,
                  child: DashboardMetricCard(
                    label: 'Total gasto',
                    value: CurrencyUtils.format(provider.currentMonthTotal),
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.error,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardMetricCard(
                    label: 'Saldo restante',
                    value: CurrencyUtils.format(remaining < 0 ? 0 : remaining),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: remaining > 0
                        ? AppColors.success
                        : AppColors.error,
                    helperText: remaining < 0 ? 'Limite ultrapassado' : null,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardMetricCard(
                    label: 'Média diária',
                    value: CurrencyUtils.format(provider.dailyAverage),
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.primary,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardMetricCard(
                    label: 'Mês anterior',
                    value: _formatPercentage(comparison),
                    icon: comparisonIcon,
                    iconColor: comparisonColor,
                    helperText: comparisonHelper,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionCard(
          title: 'Gastos por categoria',
          child: CategoryPieChart(
            totalsByCategory: provider.totalsByCategory,
            categories: categories,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionCard(
          title: 'Evolução no mês',
          child: MonthlyExpenseLineChart(
            dailyTotals: provider.dailyTotals,
            month: provider.selectedMonth,
          ),
        ),
      ],
    );
  }

  String _formatPercentage(double value) {
    if (value == 0) {
      return '0%';
    }
    final formatted = NumberFormat('0.0', 'pt_BR').format(value.abs());
    return '${value > 0 ? '+' : '-'}$formatted%';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
