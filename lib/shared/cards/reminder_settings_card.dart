import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';

class ReminderSettingsCard extends StatelessWidget {
  const ReminderSettingsCard({
    super.key,
    required this.enabled,
    required this.time,
    required this.isLoading,
    required this.onEnabledChanged,
    required this.onTimeTap,
    required this.onTestTap,
    this.embedded = false,
  });

  final bool enabled;
  final TimeOfDay time;
  final bool isLoading;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTimeTap;
  final VoidCallback onTestTap;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: embedded
            ? colorScheme.surface.withValues(alpha: 0)
            : colorScheme.surface,
        borderRadius: radius,
        boxShadow: embedded ? AppShadows.none : const [AppShadows.card],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lembrete diário',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Receba um aviso para registrar os gastos do dia.',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    label: 'Ativar lembrete diário',
                    toggled: enabled,
                    child: Switch(
                      value: enabled,
                      onChanged: isLoading ? null : onEnabledChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: isLoading ? null : onTimeTap,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(time, alwaysUse24HourFormat: true),
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: isLoading ? null : onTestTap,
                  child: const Text('Testar notificação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
