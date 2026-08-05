import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/features/categories/pages/category_form_page.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/shared/cards/category_list_card.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<InitialSetupProvider>(
      builder: (context, provider, child) {
        final categories = [
          ...provider.categories,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(title: const Text('Categorias')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crie e organize as categorias usadas nos seus gastos.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${categories.length} categorias',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return CategoryListCard(
                          category: category,
                          onEdit: () => _openForm(provider, category),
                          onDelete: _isDeleting
                              ? () {}
                              : () => _confirmDelete(provider, category),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Nova categoria',
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            onPressed: provider.isManagingCategory
                ? null
                : () => _openForm(provider, null),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Future<void> _openForm(
    InitialSetupProvider provider,
    ExpenseCategory? category,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoryFormPage(
          category: category,
          onSave:
              ({
                required name,
                required iconCodePoint,
                required iconFontFamily,
                required colorValue,
              }) {
                if (category == null) {
                  return provider.createCategory(
                    name: name,
                    iconCodePoint: iconCodePoint,
                    iconFontFamily: iconFontFamily,
                    colorValue: colorValue,
                  );
                }
                return provider.updateCategory(
                  category: category.copyWith(
                    name: name,
                    iconCodePoint: iconCodePoint,
                    iconFontFamily: iconFontFamily,
                    colorValue: colorValue,
                  ),
                );
              },
        ),
      ),
    );
    if (saved == true && category == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria criada com sucesso.')),
      );
    }
  }

  Future<void> _confirmDelete(
    InitialSetupProvider provider,
    ExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: const Text('Excluir categoria?'),
        content: const Text(
          'A categoria só poderá ser excluída se não possuir gastos vinculados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await provider.deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria excluída com sucesso.')),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        final linked =
            error.message == 'Esta categoria possui gastos vinculados.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              linked
                  ? 'Esta categoria possui gastos vinculados e não pode ser excluída.'
                  : 'Não foi possível excluir a categoria.',
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir a categoria.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
