import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/inputs/app_text_field.dart';
import 'package:quanto_posso/shared/widgets/category_color_picker.dart';
import 'package:quanto_posso/shared/widgets/category_icon_picker.dart';

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key, this.category, required this.onSave});

  final ExpenseCategory? category;
  final Future<void> Function({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int colorValue,
  })
  onSave;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name);
    _nameController.addListener(_refreshPreview);
    _selectedIcon = category == null
        ? Icons.category_rounded
        : IconData(
            // ignore: non_const_argument_for_const_parameter
            category.iconCodePoint,
            // ignore: non_const_argument_for_const_parameter
            fontFamily: category.iconFontFamily,
          );
    _selectedColorValue = category?.colorValue ?? 0xFF1D1B4F;
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refreshPreview)
      ..dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Informe o nome da categoria';
    if (name.length < 2) return 'Use pelo menos 2 caracteres';
    if (name.length > 30) return 'Use no máximo 30 caracteres';
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIcon.codePoint,
        iconFontFamily: _selectedIcon.fontFamily ?? 'MaterialIcons',
        colorValue: _selectedColorValue,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) {
        final message = switch (error) {
          ArgumentError() => error.message?.toString(),
          StateError() => error.message,
          _ => null,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Não foi possível salvar a categoria.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    final categoryColor = Color(_selectedColorValue);
    final previewName = _nameController.text.trim().isEmpty
        ? 'Categoria'
        : _nameController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(editing ? 'Editar categoria' : 'Nova categoria'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nome da categoria',
                  hint: 'Ex.: Assinaturas',
                  prefixIcon: Icons.edit_outlined,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  validator: _validateName,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle('Escolha um ícone'),
                const SizedBox(height: AppSpacing.md),
                CategoryIconPicker(
                  selectedIcon: _selectedIcon,
                  onSelected: (icon) => setState(() => _selectedIcon = icon),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle('Escolha uma cor'),
                const SizedBox(height: AppSpacing.md),
                CategoryColorPicker(
                  selectedColorValue: _selectedColorValue,
                  onSelected: (color) =>
                      setState(() => _selectedColorValue = color),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                        ),
                        child: Icon(_selectedIcon, color: categoryColor),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          previewName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: editing ? 'Salvar alterações' : 'Criar categoria',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
    );
  }
}
