import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/core/notifications/local_notification_service.dart';
import 'package:quanto_posso/features/startup/pages/startup_page.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/backup_provider.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/notification_provider.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/theme_provider.dart';
import 'package:quanto_posso/providers/recurring_expense_provider.dart';
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';
import 'package:quanto_posso/repositories/recurring_expense_repository.dart';
import 'package:quanto_posso/core/services/recurring_expense_service.dart';

import 'theme/app_theme.dart';

class QuantoPossoApp extends StatelessWidget {
  const QuantoPossoApp({
    super.key,
    this.setupRepository,
    this.expenseRepository,
    this.preferencesRepository,
    this.notificationProvider,
    this.budgetAlertProvider,
    this.backupRepository,
    this.recurringExpenseRepository,
  });

  final SetupRepository? setupRepository;
  final ExpenseRepository? expenseRepository;
  final PreferencesRepository? preferencesRepository;
  final NotificationProvider? notificationProvider;
  final BudgetAlertProvider? budgetAlertProvider;
  final BackupRepository? backupRepository;
  final RecurringExpenseRepository? recurringExpenseRepository;

  @override
  Widget build(BuildContext context) {
    final notificationService = LocalNotificationService.instance;
    final effectiveSetupRepository = setupRepository ?? SetupRepository();
    final effectiveExpenseRepository = expenseRepository ?? ExpenseRepository();
    final effectiveRecurringRepository =
        recurringExpenseRepository ??
        (expenseRepository == null ? RecurringExpenseRepository() : null);
    final recurringService = effectiveRecurringRepository == null
        ? null
        : RecurringExpenseService(repository: effectiveRecurringRepository);
    final effectivePreferencesRepository =
        preferencesRepository ?? PreferencesRepository();
    final effectiveBackupRepository =
        backupRepository ??
        BackupRepository(
          setupRepository: effectiveSetupRepository,
          expenseRepository: effectiveExpenseRepository,
          preferencesRepository: effectivePreferencesRepository,
          recurringExpenseRepository: effectiveRecurringRepository,
        );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InitialSetupProvider>(
          create: (context) =>
              InitialSetupProvider(repository: effectiveSetupRepository)
                ..initialize(),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (context) => ExpenseProvider(
            repository: effectiveExpenseRepository,
            recurringRepository: effectiveRecurringRepository,
            recurringService: recurringService,
          ),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (context) => HistoryProvider(
            repository: effectiveExpenseRepository,
            recurringService: recurringService,
          ),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(
            repository: effectiveExpenseRepository,
            recurringService: recurringService,
          ),
        ),
        ChangeNotifierProvider<RecurringExpenseProvider>(
          create: (context) => RecurringExpenseProvider(
            repository: effectiveRecurringRepository,
          ),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) =>
              ThemeProvider(repository: effectivePreferencesRepository)
                ..initialize(),
        ),
        ChangeNotifierProvider<BackupProvider>(
          create: (context) =>
              BackupProvider(repository: effectiveBackupRepository),
        ),
        notificationProvider == null
            ? ChangeNotifierProvider<NotificationProvider>(
                create: (context) => NotificationProvider(
                  preferencesRepository: effectivePreferencesRepository,
                  notificationService: notificationService,
                )..initialize(),
              )
            : ChangeNotifierProvider<NotificationProvider>.value(
                value: notificationProvider!,
              ),
        budgetAlertProvider == null
            ? ChangeNotifierProvider<BudgetAlertProvider>(
                create: (context) => BudgetAlertProvider(
                  preferencesRepository: effectivePreferencesRepository,
                  notificationService: notificationService,
                )..initialize(),
              )
            : ChangeNotifierProvider<BudgetAlertProvider>.value(
                value: budgetAlertProvider!,
              ),
      ],
      child: _RecurringLifecycle(
        service: recurringService,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => MaterialApp(
            debugShowCheckedModeBanner: false,

            title: 'Quanto Posso',

            theme: AppTheme.light,

            darkTheme: AppTheme.dark,

            themeMode: themeProvider.themeMode,

            home: const StartupPage(),
          ),
        ),
      ),
    );
  }
}

class _RecurringLifecycle extends StatefulWidget {
  const _RecurringLifecycle({required this.service, required this.child});
  final RecurringExpenseService? service;
  final Widget child;

  @override
  State<_RecurringLifecycle> createState() => _RecurringLifecycleState();
}

class _RecurringLifecycleState extends State<_RecurringLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service?.generateDueOccurrences().ignore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.service?.generateDueOccurrences().ignore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
