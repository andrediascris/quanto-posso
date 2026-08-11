import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';
import 'package:quanto_posso/features/categories/models/category_preset.dart';
import 'package:quanto_posso/features/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/cards/selectable_category_card.dart';

class CategorySetupPage extends StatefulWidget {
  const CategorySetupPage({
    super.key,
    required this.name,
    required this.monthlyIncome,
    required this.onFinish,
  });

  final String name;
  final double monthlyIncome;
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
  bool _showCompletion = false;

  void _toggleCategory(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  bool _validateSelection() {
    if (_selectedIds.isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          'Selecione pelo menos uma categoria',
          style: AppTypography.caption.copyWith(color: AppColors.textLight),
        ),
      ),
    );
    return false;
  }

  void _continue() {
    if (!_validateSelection()) return;
    setState(() => _showCompletion = true);
  }

  Future<void> _finish() async {
    if (_isSaving || !_validateSelection()) return;
    final selectedCategories = _categories
        .where((category) => _selectedIds.contains(category.id))
        .toList(growable: false);
    setState(() => _isSaving = true);
    try {
      await widget.onFinish(selectedCategories);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _isSaving
              ? null
              : _showCompletion
              ? () => setState(() => _showCompletion = false)
              : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: _showCompletion
            ? _CompletionStep(
                name: widget.name,
                monthlyIncome: widget.monthlyIncome,
                categoryCount: _selectedIds.length,
                isSaving: _isSaving,
                onFinish: _finish,
              )
            : _CategoryStep(
                categories: _categories,
                selectedIds: _selectedIds,
                onToggle: _toggleCategory,
                onContinue: _continue,
              ),
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onContinue,
  });

  final List<CategoryPreset> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(currentStep: 3),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Organize seus gastos',
            style: AppTypography.h2.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Escolha as categorias que fazem sentido para você.',
            style: AppTypography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${selectedIds.length} categorias selecionadas',
            style: AppTypography.caption.copyWith(color: colorScheme.primary),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return SelectableCategoryCard(
                  label: category.name,
                  icon: category.icon,
                  isSelected: selectedIds.contains(category.id),
                  onTap: () => onToggle(category.id),
                );
              },
            ),
          ),
          PrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({
    required this.name,
    required this.monthlyIncome,
    required this.categoryCount,
    required this.isSaving,
    required this.onFinish,
  });

  final String name;
  final double monthlyIncome;
  final int categoryCount;
  final bool isSaving;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(currentStep: 4),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tudo pronto!',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Seu controle financeiro já está configurado.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colorScheme.outline),
              boxShadow: const [AppShadows.card],
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Nome', value: name),
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(
                  label: 'Renda mensal',
                  value: CurrencyUtils.format(monthlyIncome),
                ),
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(
                  label: 'Categorias',
                  value: '$categoryCount selecionadas',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Ir para a Home',
            icon: Icons.arrow_forward_rounded,
            isLoading: isSaving,
            onPressed: isSaving ? null : onFinish,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
