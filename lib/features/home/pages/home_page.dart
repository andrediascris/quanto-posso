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
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/features/expenses/widgets/recurring_expense_badge.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.categories,
    this.onOpenHistory,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;
  final VoidCallback? onOpenHistory;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpenseProvider>().loadCurrentMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.profile.name.trim();
    final firstName = trimmedName.isEmpty
        ? widget.profile.name
        : trimmedName.split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.loadCurrentMonth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(firstName: firstName),
                    const SizedBox(height: AppSpacing.lg),
                    _AvailableBalanceCard(
                      monthlyIncome: widget.profile.monthlyIncome,
                      monthlyTotal: provider.monthlyTotal,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MonthlySummary(
                      monthlyIncome: widget.profile.monthlyIncome,
                      monthlyTotal: provider.monthlyTotal,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RecentExpensesHeader(onOpenHistory: widget.onOpenHistory),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRecentExpenses(provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(ExpenseProvider provider) {
    if (provider.status == ExpenseStatus.error) {
      return _HomeMessageCard(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar seus gastos.',
        child: PrimaryButton(
          label: 'Tentar novamente',
          onPressed: provider.loadCurrentMonth,
        ),
      );
    }

    if (provider.isLoading) {
      return const _HomeLoadingCard();
    }

    if (provider.recentExpenses.isEmpty) {
      return const _HomeMessageCard(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhum gasto registrado hoje.',
        description: 'Adicione seu primeiro gasto para acompanhar seu limite.',
      );
    }

    final expenses = provider.recentExpenses.take(5).toList(growable: false);
    return Column(
      children: [
        for (var index = 0; index < expenses.length; index++) ...[
          _HomeRecentExpenseCard(
            expense: expenses[index],
            category: _categoryFor(expenses[index]),
          ),
          if (index < expenses.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  ExpenseCategory _categoryFor(Expense expense) {
    for (final category in widget.categories) {
      if (category.id == expense.categoryId) return category;
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, $firstName!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Veja como estão seus gastos hoje.',
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AvailableBalanceCard extends StatelessWidget {
  const _AvailableBalanceCard({
    required this.monthlyIncome,
    required this.monthlyTotal,
  });

  final double monthlyIncome;
  final double monthlyTotal;

  @override
  Widget build(BuildContext context) {
    final rawAvailable = monthlyIncome - monthlyTotal;
    final available = rawAvailable < 0 ? 0.0 : rawAvailable;
    final ratio = monthlyIncome > 0 ? monthlyTotal / monthlyIncome : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final statusColor = ratio <= 0.7
        ? AppColors.success
        : ratio <= 0.9
        ? AppColors.warning
        : AppColors.error;
    final statusMessage = rawAvailable < 0
        ? 'Limite mensal ultrapassado'
        : ratio > 0.7
        ? 'Atenção ao seu limite'
        : 'Disponível neste mês';
    final availableLabel = CurrencyUtils.format(available);

    return Semantics(
      container: true,
      label:
          'Saldo atual. $availableLabel. $statusMessage. '
          '${CurrencyUtils.format(monthlyTotal)} gastos de '
          '${CurrencyUtils.format(monthlyIncome)}.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.financialCard),
          boxShadow: const [AppShadows.elevated],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saldo atual',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                availableLabel,
                maxLines: 1,
                style: AppTypography.moneyLarge.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.circle, size: AppSpacing.xs, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    statusMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.circular),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.xs,
                color: statusColor,
                backgroundColor: AppColors.surfaceDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${CurrencyUtils.format(monthlyTotal)} gastos de '
              '${CurrencyUtils.format(monthlyIncome)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.small.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({
    required this.monthlyIncome,
    required this.monthlyTotal,
  });

  final double monthlyIncome;
  final double monthlyTotal;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MonthlySummaryCard(
              label: 'Gasto neste mês',
              value: CurrencyUtils.format(monthlyTotal),
              icon: Icons.payments_outlined,
              iconColor: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MonthlySummaryCard(
              label: 'Renda mensal',
              value: CurrencyUtils.format(monthlyIncome),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.moneyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpensesHeader extends StatelessWidget {
  const _RecentExpensesHeader({this.onOpenHistory});

  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Gastos recentes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (onOpenHistory != null)
          Tooltip(
            message: 'Ver histórico',
            child: TextButton.icon(
              onPressed: onOpenHistory,
              label: Text(
                'Ver histórico',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeRecentExpenseCard extends StatelessWidget {
  const _HomeRecentExpenseCard({required this.expense, required this.category});

  final Expense expense;
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue >= 0 && category.colorValue <= 0xFFFFFFFF
        ? Color(category.colorValue)
        : Theme.of(context).colorScheme.primary;
    final icon = CategoryIconUtils.resolve(category.iconCodePoint);
    final description = expense.description?.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(icon, color: color),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (expense.recurringPlanId != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  RecurringExpenseBadge(expense: expense),
                ],
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('dd/MM/yyyy').format(expense.occurredAt),
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '- ${CurrencyUtils.format(expense.amount)}',
                maxLines: 1,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  const _HomeMessageCard({
    required this.icon,
    required this.title,
    this.description,
    this.child,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
          if (child != null) ...[const SizedBox(height: AppSpacing.md), child!],
        ],
      ),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
