import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/backup_import_preview.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/cards/backup_summary_card.dart';

class BackupRestorePreviewPage extends StatefulWidget {
  const BackupRestorePreviewPage({
    super.key,
    required this.preview,
    required this.onConfirm,
  });

  final BackupImportPreview preview;
  final Future<bool> Function() onConfirm;

  @override
  State<BackupRestorePreviewPage> createState() =>
      _BackupRestorePreviewPageState();
}

class _BackupRestorePreviewPageState extends State<BackupRestorePreviewPage> {
  bool _hasConfirmedReplacement = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Restaurar backup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WarningCard(),
              const SizedBox(height: AppSpacing.lg),
              BackupSummaryCard(preview: widget.preview),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _hasConfirmedReplacement,
                activeColor: AppColors.primary,
                title: Text(
                  'Entendo que os dados atuais ser\u00e3o substitu\u00eddos.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                onChanged: _isRestoring
                    ? null
                    : (value) => setState(
                        () => _hasConfirmedReplacement = value ?? false,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Restaurar dados',
                onPressed: _hasConfirmedReplacement && !_isRestoring
                    ? _confirmRestore
                    : null,
                isLoading: _isRestoring,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar restaura\u00e7\u00e3o?'),
        content: const Text(
          'Essa a\u00e7\u00e3o substituir\u00e1 os dados atuais e n\u00e3o poder\u00e1 ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isRestoring = true);
    final success = await widget.onConfirm();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _isRestoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('N\u00e3o foi poss\u00edvel restaurar o backup.'),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

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
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Os dados atuais ser\u00e3o substitu\u00eddos.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Seu perfil, categorias, gastos e prefer\u00eancias atuais '
                  'ser\u00e3o substitu\u00eddos pelos dados deste backup.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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
