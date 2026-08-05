import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';

class FakeSetupRepository extends SetupRepository {
  FakeSetupRepository({required List<ExpenseCategory> categories})
    : _categories = List.of(categories);

  final List<ExpenseCategory> _categories;
  final Set<String> categoriesWithExpenses = {};
  var _nextId = 1;

  List<ExpenseCategory> get savedCategories => List.unmodifiable(_categories);

  @override
  Future<bool> hasCompletedInitialSetup() async => true;

  @override
  Future<UserProfile?> getProfile() async => UserProfile(
    id: 1,
    name: 'André',
    monthlyIncome: 3000,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<List<ExpenseCategory>> getCategories() async =>
      List.unmodifiable(_categories);

  @override
  Future<bool> categoryNameExists({
    required String name,
    String? excludingId,
  }) async {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (category) =>
          category.id != excludingId &&
          category.name.toLowerCase() == normalized,
    );
  }

  @override
  Future<ExpenseCategory> createCategory({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int colorValue,
  }) async {
    final category = ExpenseCategory(
      id: 'category_${_nextId++}',
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      colorValue: colorValue,
      isDefault: false,
      createdAt: DateTime(2026),
    );
    _categories.add(category);
    return category;
  }

  @override
  Future<ExpenseCategory> updateCategory({
    required ExpenseCategory category,
  }) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index < 0) throw StateError('Categoria não encontrada.');
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    if (categoriesWithExpenses.contains(categoryId)) {
      throw StateError('Esta categoria possui gastos vinculados.');
    }
    _categories.removeWhere((category) => category.id == categoryId);
  }
}

ExpenseCategory category(String id, String name) => ExpenseCategory(
  id: id,
  name: name,
  iconCodePoint: Icons.category_rounded.codePoint,
  iconFontFamily: Icons.category_rounded.fontFamily ?? 'MaterialIcons',
  colorValue: 0xFF1D1B4F,
  isDefault: false,
  createdAt: DateTime(2026),
);

Future<InitialSetupProvider> initializedProvider(
  FakeSetupRepository repository,
) async {
  final provider = InitialSetupProvider(repository: repository);
  await provider.initialize();
  return provider;
}

void main() {
  test('criar categoria adiciona à lista e mantém ordem alfabética', () async {
    final repository = FakeSetupRepository(
      categories: [category('z', 'Zoológico')],
    );
    final provider = await initializedProvider(repository);

    await provider.createCategory(
      name: 'Alimentação',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFF9A826,
    );

    expect(provider.categories.map((item) => item.name), [
      'Alimentação',
      'Zoológico',
    ]);
    expect(
      repository.savedCategories.where(
        (category) => category.name == 'Alimentação',
      ),
      hasLength(1),
    );
    expect(
      provider.categories.where((category) => category.name == 'Alimentação'),
      hasLength(1),
    );
  });

  test('nome duplicado é rejeitado', () async {
    final provider = await initializedProvider(
      FakeSetupRepository(categories: [category('food', 'Alimentação')]),
    );

    expect(
      () => provider.createCategory(
        name: ' alimentação ',
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        iconFontFamily: 'MaterialIcons',
        colorValue: 0xFFF9A826,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('editar categoria atualiza nome, ícone e cor', () async {
    final original = category('food', 'Alimentação');
    final provider = await initializedProvider(
      FakeSetupRepository(categories: [original]),
    );

    await provider.updateCategory(
      category: original.copyWith(
        name: 'Mercado',
        iconCodePoint: Icons.shopping_cart_rounded.codePoint,
        colorValue: 0xFF2ECC71,
      ),
    );

    expect(provider.categories.single.name, 'Mercado');
    expect(
      provider.categories.single.iconCodePoint,
      Icons.shopping_cart_rounded.codePoint,
    );
    expect(provider.categories.single.colorValue, 0xFF2ECC71);
  });

  test('excluir categoria sem gastos remove da lista', () async {
    final repository = FakeSetupRepository(
      categories: [category('food', 'Alimentação')],
    );
    final provider = await initializedProvider(repository);

    await provider.deleteCategory('food');

    expect(provider.categories, isEmpty);
  });

  test('excluir categoria com gastos mantém lista e retorna erro', () async {
    final repository = FakeSetupRepository(
      categories: [category('food', 'Alimentação')],
    )..categoriesWithExpenses.add('food');
    final provider = await initializedProvider(repository);

    await expectLater(
      provider.deleteCategory('food'),
      throwsA(isA<StateError>()),
    );

    expect(provider.categories, hasLength(1));
    expect(
      provider.categoryErrorMessage,
      'Esta categoria possui gastos vinculados.',
    );
  });

  test('categorias editadas permanecem ordenadas alfabeticamente', () async {
    final first = category('first', 'Alimentação');
    final second = category('second', 'Moradia');
    final provider = await initializedProvider(
      FakeSetupRepository(categories: [first, second]),
    );

    await provider.updateCategory(category: first.copyWith(name: 'Transporte'));

    expect(provider.categories.map((item) => item.name), [
      'Moradia',
      'Transporte',
    ]);
  });
}
