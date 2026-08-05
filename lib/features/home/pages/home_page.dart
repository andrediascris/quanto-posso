import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/models/expense.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/shared/cards/recent_expense_card.dart';

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
      if (mounted) {
        context.read<ExpenseProvider>().loadCurrentMonth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.profile.name.trim();
    final firstName = trimmedName.isEmpty
        ? widget.profile.name
        : trimmedName.split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Olá, $firstName!',
                    style: AppTypography.h2.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Seu perfil foi configurado com sucesso.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _FinancialSummaryCard(
                    monthlyIncome: widget.profile.monthlyIncome,
                    monthlyTotal: provider.monthlyTotal,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Últimos gastos',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (widget.onOpenHistory != null)
                        TextButton(
                          onPressed: widget.onOpenHistory,
                          child: Text(
                            'Ver histórico',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRecentExpenses(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(ExpenseProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.recentExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [AppShadows.card],
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Nenhum gasto registrado ainda.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (
          var index = 0;
          index < provider.recentExpenses.length;
          index++
        ) ...[
          RecentExpenseCard(
            expense: provider.recentExpenses[index],
            category: _categoryFor(provider.recentExpenses[index]),
          ),
          if (index < provider.recentExpenses.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
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

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.monthlyIncome,
    required this.monthlyTotal,
  });

  final double monthlyIncome;
  final double monthlyTotal;

  @override
  Widget build(BuildContext context) {
    final rawRemaining = monthlyIncome - monthlyTotal;
    final remaining = rawRemaining < 0 ? 0.0 : rawRemaining;
    final ratio = monthlyIncome > 0 ? monthlyTotal / monthlyIncome : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final progressColor = ratio <= 0.7
        ? AppColors.success
        : ratio <= 0.9
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.financialCard),
        boxShadow: const [AppShadows.elevated],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ainda pode gastar',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyUtils.format(remaining),
            style: AppTypography.moneyLarge.copyWith(color: AppColors.primary),
          ),
          if (rawRemaining < 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Limite mensal ultrapassado.',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gasto neste mês',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyUtils.format(monthlyTotal),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            color: progressColor,
            backgroundColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
