import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';

class BackupSummaryCard extends StatelessWidget {
  const BackupSummaryCard({super.key, required this.preview});

  final BackupImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy HH:mm').format(preview.exportedAt);
    return Semantics(
      container: true,
      label: 'Resumo do backup selecionado',
      child: Container(
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
              'Resumo do backup',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(label: 'Arquivo', value: preview.fileName),
            _SummaryRow(label: 'Perfil', value: preview.profileName),
            _SummaryRow(
              label: 'Renda mensal',
              value: currency.format(preview.monthlyIncome),
            ),
            _SummaryRow(
              label: 'Categorias',
              value: preview.categoryCount.toString(),
            ),
            _SummaryRow(
              label: 'Gastos',
              value: preview.expenseCount.toString(),
            ),
            _SummaryRow(label: 'Data do backup', value: date),
            _SummaryRow(
              label: 'Vers\u00e3o',
              value: preview.backupVersion.toString(),
              showSpacing: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.showSpacing = true,
  });

  final String label;
  final String value;
  final bool showSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showSpacing ? AppSpacing.sm : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
