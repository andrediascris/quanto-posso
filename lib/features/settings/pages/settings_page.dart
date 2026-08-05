import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/categories/pages/category_management_page.dart';
import 'package:quanto_posso/features/settings/pages/edit_profile_page.dart';
import 'package:quanto_posso/features/settings/pages/backup_page.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/budget_alert_provider.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/providers/notification_provider.dart';
import 'package:quanto_posso/providers/theme_provider.dart';
import 'package:quanto_posso/shared/cards/reminder_settings_card.dart';
import 'package:quanto_posso/shared/cards/budget_alert_settings_card.dart';
import 'package:quanto_posso/shared/cards/settings_item_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.profile,
    required this.categories,
    this.onProfileUpdated,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;
  final Future<void> Function()? onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    final setupProvider = context.watch<InitialSetupProvider>();
    final currentProfile = setupProvider.profile ?? profile;
    final themeProvider = context.watch<ThemeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final budgetAlertProvider = context.watch<BudgetAlertProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configurações',
                style: AppTypography.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Personalize o aplicativo e gerencie seus dados.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Perfil'),
              const SizedBox(height: AppSpacing.sm),
              SettingsItemCard(
                icon: Icons.person_outline_rounded,
                title: currentProfile.name,
                subtitle: CurrencyUtils.format(currentProfile.monthlyIncome),
                onTap: () =>
                    _openEditProfile(context, setupProvider, currentProfile),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Aparência'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Sistema'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Escuro'),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (selection) async {
                    try {
                      await themeProvider.setThemeMode(selection.first);
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Não foi possível alterar o tema.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Notificações'),
              const SizedBox(height: AppSpacing.sm),
              ReminderSettingsCard(
                enabled: notificationProvider.preferences.enabled,
                time: TimeOfDay(
                  hour: notificationProvider.preferences.hour,
                  minute: notificationProvider.preferences.minute,
                ),
                isLoading:
                    notificationProvider.isLoading ||
                    notificationProvider.isSaving,
                onEnabledChanged: (enabled) =>
                    _setReminderEnabled(context, notificationProvider, enabled),
                onTimeTap: () =>
                    _selectReminderTime(context, notificationProvider),
                onTestTap: () =>
                    _sendTestNotification(context, notificationProvider),
              ),
              const SizedBox(height: AppSpacing.md),
              BudgetAlertSettingsCard(
                enabled: budgetAlertProvider.preferences.enabled,
                thresholdPercentage:
                    budgetAlertProvider.preferences.thresholdPercentage,
                isLoading:
                    budgetAlertProvider.isLoading ||
                    budgetAlertProvider.isSaving,
                onEnabledChanged: (enabled) => _setBudgetAlertEnabled(
                  context,
                  budgetAlertProvider,
                  enabled,
                ),
                onThresholdChanged: (percentage) => _setBudgetAlertThreshold(
                  context,
                  budgetAlertProvider,
                  percentage,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Categorias'),
              const SizedBox(height: AppSpacing.sm),
              SettingsItemCard(
                icon: Icons.category_outlined,
                title: 'Categorias',
                subtitle:
                    '${setupProvider.categories.length} categorias configuradas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoryManagementPage(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Dados'),
              const SizedBox(height: AppSpacing.sm),
              SettingsItemCard(
                icon: Icons.cloud_upload_outlined,
                title: 'Backup e dados',
                subtitle: 'Exporte uma c\u00f3pia local dos seus dados',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BackupPage()),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Privacidade'),
              const SizedBox(height: AppSpacing.sm),
              const SettingsItemCard(
                icon: Icons.lock_outline_rounded,
                title: 'Seus dados ficam neste dispositivo',
                subtitle:
                    'O Quanto Posso funciona offline e não envia seus '
                    'dados financeiros para servidores.',
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Sobre'),
              const SizedBox(height: AppSpacing.sm),
              const SettingsItemCard(
                icon: Icons.info_outline_rounded,
                title: 'Quanto Posso',
                subtitle: 'Versão 1.0.0',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setReminderEnabled(
    BuildContext context,
    NotificationProvider provider,
    bool enabled,
  ) async {
    try {
      final success = await provider.setEnabled(enabled);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permita as notificações para ativar o lembrete.'),
          ),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o lembrete.'),
          ),
        );
      }
    }
  }

  Future<void> _setBudgetAlertEnabled(
    BuildContext context,
    BudgetAlertProvider provider,
    bool enabled,
  ) async {
    try {
      final success = await provider.setEnabled(enabled);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permita as notificações para ativar o alerta.'),
          ),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o alerta de limite.'),
          ),
        );
      }
    }
  }

  Future<void> _setBudgetAlertThreshold(
    BuildContext context,
    BudgetAlertProvider provider,
    int percentage,
  ) async {
    try {
      await provider.setThresholdPercentage(percentage);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o alerta de limite.'),
          ),
        );
      }
    }
  }

  Future<void> _selectReminderTime(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: provider.preferences.hour,
        minute: provider.preferences.minute,
      ),
    );
    if (selected == null || !context.mounted) return;
    try {
      await provider.setTime(hour: selected.hour, minute: selected.minute);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o lembrete.'),
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    try {
      final sent = await provider.sendTestNotification();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Notificação de teste enviada.'
                : 'Permita as notificações para ativar o lembrete.',
          ),
        ),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar a notificação de teste.'),
          ),
        );
      }
    }
  }

  Future<void> _openEditProfile(
    BuildContext context,
    InitialSetupProvider provider,
    UserProfile currentProfile,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfilePage(
          profile: currentProfile,
          onSave: ({required name, required monthlyIncome}) {
            return provider.updateProfile(
              name: name,
              monthlyIncome: monthlyIncome,
            );
          },
        ),
      ),
    );
    if (updated == true && context.mounted) {
      await onProfileUpdated?.call();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
    );
  }
}
