import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/features/categories/models/category_preset.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/cards/selectable_category_card.dart';

class CategorySetupPage extends StatefulWidget {
  const CategorySetupPage({super.key, required this.onFinish});

  final Future<void> Function(List<CategoryPreset> selectedCategories) onFinish;

  @override
  State<CategorySetupPage> createState() => _CategorySetupPageState();
}

class _CategorySetupPageState extends State<CategorySetupPage> {
  static const _categories = [
    CategoryPreset(
      id: 'food',
      name: 'Alimentação',
      icon: Icons.restaurant_rounded,
    ),
    CategoryPreset(
      id: 'market',
      name: 'Mercado',
      icon: Icons.shopping_cart_rounded,
    ),
    CategoryPreset(
      id: 'transport',
      name: 'Transporte',
      icon: Icons.directions_car_rounded,
    ),
    CategoryPreset(id: 'housing', name: 'Moradia', icon: Icons.home_rounded),
    CategoryPreset(id: 'water', name: 'Água', icon: Icons.water_drop_rounded),
    CategoryPreset(
      id: 'electricity',
      name: 'Luz',
      icon: Icons.lightbulb_rounded,
    ),
    CategoryPreset(id: 'internet', name: 'Internet', icon: Icons.wifi_rounded),
    CategoryPreset(
      id: 'health',
      name: 'Saúde',
      icon: Icons.health_and_safety_rounded,
    ),
    CategoryPreset(
      id: 'leisure',
      name: 'Lazer',
      icon: Icons.sports_esports_rounded,
    ),
    CategoryPreset(
      id: 'credit',
      name: 'Crédito',
      icon: Icons.credit_card_rounded,
    ),
  ];

  final Set<String> _selectedIds = {
    'food',
    'market',
    'transport',
    'housing',
    'water',
    'electricity',
    'internet',
  };
  bool _isSaving = false;

  void _toggleCategory(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _finish() async {
    if (_isSaving) {
      return;
    }

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Selecione pelo menos uma categoria',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
        ),
      );
      return;
    }

    final selectedCategories = _categories
        .where((category) => _selectedIds.contains(category.id))
        .toList(growable: false);

    setState(() => _isSaving = true);

    try {
      await widget.onFinish(selectedCategories);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                'Escolha suas categorias',
                style: AppTypography.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Selecione as categorias que fazem parte da sua rotina. '
                'Você poderá alterar isso depois.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_selectedIds.length} categorias selecionadas',
                style: AppTypography.caption.copyWith(color: AppColors.primary),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];

                    return SelectableCategoryCard(
                      label: category.name,
                      icon: category.icon,
                      isSelected: _selectedIds.contains(category.id),
                      onTap: () => _toggleCategory(category.id),
                    );
                  },
                ),
              ),
              PrimaryButton(
                label: 'Finalizar configuração',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
