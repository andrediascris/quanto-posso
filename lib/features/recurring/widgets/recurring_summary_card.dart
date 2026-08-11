import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';

class RecurringSummaryCard extends StatelessWidget {
  const RecurringSummaryCard({
    super.key,
    required this.monthlyCommitment,
    required this.subscriptions,
    required this.installments,
  });

  final double monthlyCommitment;
  final int subscriptions;
  final int installments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comprometido por mês',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyUtils.format(monthlyCommitment),
              style: AppTypography.moneyMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Count(label: 'Assinaturas ativas', value: subscriptions),
              _Count(label: 'Parcelamentos', value: installments),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Text(
    '$value $label',
    style: AppTypography.caption.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
