import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/providers/backup_provider.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/dashboard_provider.dart';
import 'package:quanto_posso/providers/expense_provider.dart';
import 'package:quanto_posso/providers/history_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/notification_provider.dart';
import 'package:quanto_posso/providers/theme_provider.dart';
import 'package:quanto_posso/repositories/backup_repository.dart';
import 'package:quanto_posso/features/settings/pages/backup_restore_preview_page.dart';
import 'package:quanto_posso/shared/cards/backup_action_card.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Backup e dados')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Consumer<BackupProvider>(
            builder: (context, provider, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Proteja seus dados',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Crie uma c\u00f3pia dos seus dados para guardar ou compartilhar.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _InformationCard(),
                const SizedBox(height: AppSpacing.lg),
                BackupActionCard(
                  icon: Icons.backup_outlined,
                  title: 'Criar backup',
                  description:
                      'Exporte seu perfil, categorias, gastos e prefer\u00eancias '
                      'em um arquivo JSON.',
                  buttonLabel: 'Criar e compartilhar',
                  onPressed: provider.isExporting
                      ? null
                      : () => _export(context, provider),
                  isLoading: provider.isExporting,
                ),
                if (provider.lastExport case final lastExport?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _LastExportCard(result: lastExport),
                ],
                const SizedBox(height: AppSpacing.xl),
                BackupActionCard(
                  icon: Icons.restore_rounded,
                  title: 'Restaurar backup',
                  description:
                      'Substitua os dados atuais usando um arquivo JSON criado '
                      'pelo Quanto Posso.',
                  buttonLabel: 'Selecionar arquivo',
                  onPressed: provider.isSelecting
                      ? null
                      : () => _selectBackup(context, provider),
                  isLoading: provider.isSelecting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, BackupProvider provider) async {
    final success = await provider.exportBackup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Backup criado com sucesso.'
              : 'N\u00e3o foi poss\u00edvel criar o backup.',
        ),
      ),
    );
  }

  Future<void> _selectBackup(
    BuildContext context,
    BackupProvider provider,
  ) async {
    final preview = await provider.selectBackup();
    if (!context.mounted) return;
    if (preview == null) {
      final message = provider.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BackupRestorePreviewPage(
          preview: preview,
          onConfirm: provider.restoreSelectedBackup,
        ),
      ),
    );
    if (!context.mounted) return;
    if (restored != true) {
      provider.cancelRestorePreview();
      return;
    }
    await _reloadApplication(context);
    if (!context.mounted) return;
    final message = provider.wasPartialRestore
        ? 'Dados restaurados. Algumas prefer\u00eancias n\u00e3o puderam ser aplicadas.'
        : 'Backup restaurado com sucesso.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reloadApplication(BuildContext context) async {
    await context.read<InitialSetupProvider>().initialize();
    if (!context.mounted) return;
    await context.read<ExpenseProvider>().loadCurrentMonth();
    if (!context.mounted) return;
    await context.read<HistoryProvider>().loadHistory();
    if (!context.mounted) return;
    await context.read<DashboardProvider>().loadDashboard();
    if (!context.mounted) return;
    await context.read<ThemeProvider>().initialize();
    if (!context.mounted) return;
    await context.read<NotificationProvider>().initialize();
    if (!context.mounted) return;
    await context.read<BudgetAlertProvider>().initialize();
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'O backup \u00e9 criado somente no seu dispositivo e n\u00e3o \u00e9 enviado '
              'automaticamente para nenhum servidor. Armazene o arquivo com '
              'cuidado, pois ele cont\u00e9m seus dados financeiros.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastExportCard extends StatelessWidget {
  const _LastExportCard({required this.result});

  final BackupExportResult result;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(result.exportedAt);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u00daltimo backup desta sess\u00e3o',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(result.fileName, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${result.categoryCount} categorias \u2022 ${result.expenseCount} gastos',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            date,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
