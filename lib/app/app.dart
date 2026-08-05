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
import 'package:quanto_posso/repositories/expense_repository.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';

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
  });

  final SetupRepository? setupRepository;
  final ExpenseRepository? expenseRepository;
  final PreferencesRepository? preferencesRepository;
  final NotificationProvider? notificationProvider;
  final BudgetAlertProvider? budgetAlertProvider;
  final BackupRepository? backupRepository;

  @override
  Widget build(BuildContext context) {
    final notificationService = LocalNotificationService.instance;
    final effectiveSetupRepository = setupRepository ?? SetupRepository();
    final effectiveExpenseRepository = expenseRepository ?? ExpenseRepository();
    final effectivePreferencesRepository =
        preferencesRepository ?? PreferencesRepository();
    final effectiveBackupRepository =
        backupRepository ??
        BackupRepository(
          setupRepository: effectiveSetupRepository,
          expenseRepository: effectiveExpenseRepository,
          preferencesRepository: effectivePreferencesRepository,
        );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InitialSetupProvider>(
          create: (context) =>
              InitialSetupProvider(repository: effectiveSetupRepository)
                ..initialize(),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (context) =>
              ExpenseProvider(repository: effectiveExpenseRepository),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (context) =>
              HistoryProvider(repository: effectiveExpenseRepository),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) =>
              DashboardProvider(repository: effectiveExpenseRepository),
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
    );
  }
}
