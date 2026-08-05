import 'package:quanto_posso/core/database/app_database.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:sqflite/sqflite.dart';

class SetupRepository {
  SetupRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  static const _profilesTable = 'profiles';
  static const _categoriesTable = 'categories';
  static const _expensesTable = 'expenses';

  final AppDatabase _database;

  Future<void> saveInitialSetup({
    required UserProfile profile,
    required List<ExpenseCategory> categories,
  }) async {
    final database = await _database.database;

    await database.transaction((transaction) async {
      await transaction.insert(
        _profilesTable,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await transaction.delete(_categoriesTable);

      final batch = transaction.batch();
      for (final category in categories) {
        batch.insert(_categoriesTable, category.toMap());
      }

      await batch.commit(noResult: true);
    });
  }

  Future<UserProfile?> getProfile() async {
    final database = await _database.database;
    final profiles = await database.query(_profilesTable, limit: 1);

    if (profiles.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(profiles.first);
  }

  Future<List<ExpenseCategory>> getCategories() async {
    final database = await _database.database;
    final categories = await database.query(
      _categoriesTable,
      orderBy: 'name ASC',
    );

    return categories.map(ExpenseCategory.fromMap).toList(growable: false);
  }

  Future<bool> hasCompletedInitialSetup() async {
    final profile = await getProfile();
    if (profile == null) {
      return false;
    }

    final categories = await getCategories();
    return categories.isNotEmpty;
  }

  Future<void> clearInitialSetup() async {
    final database = await _database.database;

    await database.transaction((transaction) async {
      await transaction.delete(_categoriesTable);
      await transaction.delete(_profilesTable);
    });
  }

  Future<UserProfile> updateProfile({required UserProfile profile}) async {
    if (profile.id != 1) {
      throw ArgumentError.value(profile.id, 'profile.id', 'Deve ser igual a 1');
    }

    final name = profile.name.trim();
    if (name.length < 2) {
      throw ArgumentError.value(name, 'profile.name', 'Nome inválido');
    }
    if (!(profile.monthlyIncome > 0)) {
      throw ArgumentError.value(
        profile.monthlyIncome,
        'profile.monthlyIncome',
        'Deve ser maior que zero',
      );
    }

    final updatedProfile = profile.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
    final database = await _database.database;
    final updatedRows = await database.update(
      _profilesTable,
      updatedProfile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );

    if (updatedRows == 0) {
      throw StateError('Perfil não encontrado');
    }

    return updatedProfile;
  }

  Future<ExpenseCategory> createCategory({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int colorValue,
  }) async {
    final normalizedName = _validateCategoryName(name);
    final now = DateTime.now();
    final category = ExpenseCategory(
      id: '${_normalizeForId(normalizedName)}_${now.microsecondsSinceEpoch}',
      name: normalizedName,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      colorValue: colorValue,
      isDefault: false,
      createdAt: now,
    );
    final database = await _database.database;
    await database.insert(_categoriesTable, category.toMap());
    return category;
  }

  Future<ExpenseCategory> updateCategory({
    required ExpenseCategory category,
  }) async {
    final updatedCategory = category.copyWith(
      name: _validateCategoryName(category.name),
    );
    final database = await _database.database;
    final updatedRows = await database.update(
      _categoriesTable,
      updatedCategory.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    if (updatedRows == 0) {
      throw StateError('Categoria não encontrada.');
    }
    return updatedCategory;
  }

  Future<int> getExpenseCountForCategory(String categoryId) async {
    final database = await _database.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM $_expensesTable WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['total'] as num).toInt();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (await getExpenseCountForCategory(categoryId) > 0) {
      throw StateError('Esta categoria possui gastos vinculados.');
    }
    final database = await _database.database;
    final deletedRows = await database.delete(
      _categoriesTable,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    if (deletedRows == 0) {
      throw StateError('Categoria não encontrada.');
    }
  }

  Future<bool> categoryNameExists({
    required String name,
    String? excludingId,
  }) async {
    final database = await _database.database;
    final normalizedName = name.trim();
    final result = await database.query(
      _categoriesTable,
      columns: const ['id'],
      where: excludingId == null
          ? 'LOWER(name) = LOWER(?)'
          : 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: excludingId == null
          ? [normalizedName]
          : [normalizedName, excludingId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  String _validateCategoryName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.length < 2) {
      throw ArgumentError.value(name, 'name', 'Nome inválido.');
    }
    return normalizedName;
  }

  String _normalizeForId(String name) {
    const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    final buffer = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = accented.indexOf(character);
      final normalized = index >= 0 ? plain[index] : character;
      if (RegExp(r'[a-z0-9]').hasMatch(normalized)) {
        buffer.write(normalized);
      } else if (buffer.isNotEmpty && !buffer.toString().endsWith('_')) {
        buffer.write('_');
      }
    }
    final result = buffer.toString().replaceFirst(RegExp(r'_+$'), '');
    return result.isEmpty ? 'categoria' : result;
  }
}
