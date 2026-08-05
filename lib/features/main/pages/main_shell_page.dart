import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/features/dashboard/pages/dashboard_page.dart';
import 'package:quanto_posso/features/expenses/pages/add_expense_page.dart';
import 'package:quanto_posso/features/history/pages/history_page.dart';
import 'package:quanto_posso/features/home/pages/home_page.dart';
import 'package:quanto_posso/features/settings/pages/settings_page.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/shared/navigation/app_bottom_navigation.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.profile,
    required this.categories,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  bool _isEvaluatingBudget = false;
  ExpenseProvider? _expenseProvider;
  InitialSetupProvider? _setupProvider;
  BudgetAlertProvider? _budgetAlertProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expenseProvider = context.read<ExpenseProvider>();
    final setupProvider = context.read<InitialSetupProvider>();
    final budgetAlertProvider = context.read<BudgetAlertProvider>();
    if (_expenseProvider != expenseProvider) {
      _expenseProvider?.removeListener(_handleExpenseChanged);
      _expenseProvider = expenseProvider..addListener(_handleExpenseChanged);
    }
    if (_setupProvider != setupProvider) {
      _setupProvider?.removeListener(_handleSetupChanged);
      _setupProvider = setupProvider..addListener(_handleSetupChanged);
    }
    if (_budgetAlertProvider != budgetAlertProvider) {
      _budgetAlertProvider?.removeListener(_handleBudgetAlertChanged);
      _budgetAlertProvider = budgetAlertProvider
        ..addListener(_handleBudgetAlertChanged);
    }
  }

  @override
  void dispose() {
    _expenseProvider?.removeListener(_handleExpenseChanged);
    _setupProvider?.removeListener(_handleSetupChanged);
    _budgetAlertProvider?.removeListener(_handleBudgetAlertChanged);
    super.dispose();
  }

  void _handleExpenseChanged() {
    if (_expenseProvider?.status == ExpenseStatus.ready) {
      _evaluateBudgetAlert();
    }
  }

  void _handleSetupChanged() {
    if (_setupProvider?.profile != null &&
        _expenseProvider?.status == ExpenseStatus.ready) {
      _evaluateBudgetAlert();
    }
  }

  void _handleBudgetAlertChanged() {
    if (_budgetAlertProvider?.status == BudgetAlertStatus.ready &&
        _expenseProvider?.status == ExpenseStatus.ready) {
      _evaluateBudgetAlert();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InitialSetupProvider>(
      builder: (context, setupProvider, child) {
        final categories = setupProvider.categories;
        final profile = setupProvider.profile ?? widget.profile;
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                profile: profile,
                categories: categories,
                onOpenHistory: () => setState(() => _currentIndex = 2),
              ),
              DashboardPage(profile: profile, categories: categories),
              HistoryPage(categories: categories),
              SettingsPage(
                profile: profile,
                categories: categories,
                onProfileUpdated: _evaluateBudgetAlert,
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              if (index == 1) {
                final provider = context.read<DashboardProvider>();
                if (!provider.isLoading) {
                  provider.loadDashboard();
                }
              }
            },
          ),
          floatingActionButton: _currentIndex == 0 || _currentIndex == 2
              ? FloatingActionButton(
                  tooltip: 'Adicionar gasto',
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primary,
                  onPressed: _openAddExpense,
                  child: const Icon(Icons.add_rounded),
                )
              : null,
        );
      },
    );
  }

  void _openAddExpense() {
    final expenseProvider = context.read<ExpenseProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AddExpensePage(
          categories: context.read<InitialSetupProvider>().categories,
          onSave:
              ({
                required amount,
                required categoryId,
                description,
                required occurredAt,
              }) async {
                await expenseProvider.addExpense(
                  amount: amount,
                  categoryId: categoryId,
                  description: description,
                  occurredAt: occurredAt,
                );
                if (mounted) {
                  await historyProvider.loadHistory();
                  await dashboardProvider.loadDashboard();
                  await _evaluateBudgetAlert();
                }
              },
        ),
      ),
    );
  }

  Future<void> _evaluateBudgetAlert() async {
    if (_isEvaluatingBudget || !mounted) return;
    final budgetAlertProvider = context.read<BudgetAlertProvider>();
    if (budgetAlertProvider.status != BudgetAlertStatus.ready) return;
    final profile = context.read<InitialSetupProvider>().profile;
    if (profile == null) return;
    _isEvaluatingBudget = true;
    try {
      await budgetAlertProvider.evaluateBudget(
        monthlyIncome: profile.monthlyIncome,
        monthlyExpenseTotal: context.read<ExpenseProvider>().monthlyTotal,
      );
    } on Object {
      // O provider mantém o estado de erro; alertas automáticos não interrompem a UI.
    } finally {
      _isEvaluatingBudget = false;
    }
  }
}
