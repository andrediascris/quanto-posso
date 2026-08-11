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
import 'package:quanto_posso/features/recurring/pages/recurring_expenses_page.dart';
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
    this.onAddExpense,
  });

  final UserProfile profile;
  final List<ExpenseCategory> categories;
  final Future<void> Function()? onProfileUpdated;
  final Future<void> Function()? onAddExpense;

  @override
  Widget build(BuildContext context) {
    final setupProvider = context.watch<InitialSetupProvider>();
    final currentProfile = setupProvider.profile ?? profile;
    final themeProvider = context.watch<ThemeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final budgetAlertProvider = context.watch<BudgetAlertProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                style: AppTypography.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Personalize o aplicativo e gerencie seus dados.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Perfil'),
              const SizedBox(height: AppSpacing.sm),
              _ProfileCard(
                profile: currentProfile,
                onTap: () =>
                    _openEditProfile(context, setupProvider, currentProfile),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Aparência'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SettingsCardHeader(
                      icon: Icons.palette_outlined,
                      title: 'Tema do aplicativo',
                      subtitle: 'Escolha como o Quanto Posso deve aparecer.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Claro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
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
                                content: Text(
                                  'Não foi possível alterar o tema.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Notificações'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSectionCard(
                children: [
                  ReminderSettingsCard(
                    embedded: true,
                    enabled: notificationProvider.preferences.enabled,
                    time: TimeOfDay(
                      hour: notificationProvider.preferences.hour,
                      minute: notificationProvider.preferences.minute,
                    ),
                    isLoading:
                        notificationProvider.isLoading ||
                        notificationProvider.isSaving,
                    onEnabledChanged: (enabled) => _setReminderEnabled(
                      context,
                      notificationProvider,
                      enabled,
                    ),
                    onTimeTap: () =>
                        _selectReminderTime(context, notificationProvider),
                    onTestTap: () =>
                        _sendTestNotification(context, notificationProvider),
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: AppSpacing.xs,
                  ),
                  BudgetAlertSettingsCard(
                    embedded: true,
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
                    onThresholdChanged: (percentage) =>
                        _setBudgetAlertThreshold(
                          context,
                          budgetAlertProvider,
                          percentage,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Organização'),
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
              const SizedBox(height: AppSpacing.sm),
              SettingsItemCard(
                icon: Icons.autorenew_rounded,
                title: 'Recorrências',
                subtitle: 'Assinaturas e compras parceladas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecurringExpensesPage(
                      onAddExpense: onAddExpense ?? () async {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Dados e privacidade'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSectionCard(
                children: [
                  SettingsItemCard(
                    embedded: true,
                    icon: Icons.backup_outlined,
                    title: 'Backup e dados',
                    subtitle: 'Exporte ou restaure uma cópia dos seus dados',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BackupPage(),
                      ),
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: AppSpacing.xs,
                  ),
                  const SettingsItemCard(
                    embedded: true,
                    showChevron: false,
                    icon: Icons.lock_outline_rounded,
                    title: 'Seus dados ficam neste dispositivo',
                    subtitle:
                        'O Quanto Posso funciona offline e não envia seus '
                        'dados financeiros para servidores.',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Sobre'),
              const SizedBox(height: AppSpacing.sm),
              const _AboutCard(),
              const SizedBox(height: AppSpacing.xxl),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      label: 'Editar perfil de ${profile.name}',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: radius,
          boxShadow: const [AppShadows.card],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Renda mensal: '
                          '${CurrencyUtils.format(profile.monthlyIncome)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textLight.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Editar perfil',
                          style: AppTypography.small.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCardHeader extends StatelessWidget {
  const _SettingsCardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quanto Posso',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Controle financeiro pessoal offline',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Versão 1.0.0',
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
