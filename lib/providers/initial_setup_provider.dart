import 'package:flutter/foundation.dart';
import 'package:quanto_posso/features/categories/models/category_preset.dart';
import 'package:quanto_posso/models/expense_category.dart';
import 'package:quanto_posso/models/user_profile.dart';
import 'package:quanto_posso/repositories/setup_repository.dart';

enum InitialSetupStatus {
  initial,
  loading,
  requiresSetup,
  saving,
  completed,
  error,
}

class InitialSetupProvider extends ChangeNotifier {
  InitialSetupProvider({SetupRepository? repository})
    : _repository = repository ?? SetupRepository();

  final SetupRepository _repository;

  InitialSetupStatus _status = InitialSetupStatus.initial;
  UserProfile? _profile;
  List<ExpenseCategory> _categories = [];
  String? _errorMessage;
  bool _isManagingCategory = false;
  String? _categoryErrorMessage;

  InitialSetupStatus get status => _status;
  UserProfile? get profile => _profile;
  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  String? get errorMessage => _errorMessage;
  bool get isManagingCategory => _isManagingCategory;
  String? get categoryErrorMessage => _categoryErrorMessage;

  Future<void> initialize() async {
    _status = InitialSetupStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasCompletedSetup = await _repository.hasCompletedInitialSetup();

      if (!hasCompletedSetup) {
        _profile = null;
        _categories = [];
        _status = InitialSetupStatus.requiresSetup;
        notifyListeners();
        return;
      }

      _profile = await _repository.getProfile();
      _categories = List.of(await _repository.getCategories());
      _status = InitialSetupStatus.completed;
    } on Object {
      _errorMessage = 'Não foi possível carregar seus dados.';
      _status = InitialSetupStatus.error;
    }

    notifyListeners();
  }

  Future<void> completeSetup({
    required String name,
    required double monthlyIncome,
    required List<CategoryPreset> selectedCategories,
  }) async {
    _status = InitialSetupStatus.saving;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final profile = UserProfile(
      id: 1,
      name: name.trim(),
      monthlyIncome: monthlyIncome,
      createdAt: now,
      updatedAt: now,
    );
    const categoryColors = <int>[
      0xFF1D1B4F,
      0xFFF9A826,
      0xFF2ECC71,
      0xFFF4B400,
      0xFF3498DB,
      0xFFF4B400,
      0xFF7E57C2,
      0xFF26A69A,
      0xFFEC407A,
      0xFF8D6E63,
    ];
    final categories = selectedCategories.indexed
        .map(
          (entry) => ExpenseCategory(
            colorValue: categoryColors[entry.$1 % categoryColors.length],
            id: entry.$2.id,
            name: entry.$2.name,
            iconCodePoint: entry.$2.icon.codePoint,
            iconFontFamily: entry.$2.icon.fontFamily ?? 'MaterialIcons',
            isDefault: true,
            createdAt: now,
          ),
        )
        .toList(growable: false);

    try {
      await _repository.saveInitialSetup(
        profile: profile,
        categories: categories,
      );

      _profile = profile;
      _categories = List.of(categories);
      _status = InitialSetupStatus.completed;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível salvar sua configuração.';
      _status = InitialSetupStatus.requiresSetup;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required double monthlyIncome,
  }) async {
    final currentProfile = _profile;
    if (currentProfile == null) {
      throw StateError('Perfil não carregado');
    }

    final previousStatus = _status;
    _status = InitialSetupStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = currentProfile.copyWith(
        name: name.trim(),
        monthlyIncome: monthlyIncome,
        updatedAt: DateTime.now(),
      );
      _profile = await _repository.updateProfile(profile: updatedProfile);
      _status = InitialSetupStatus.completed;
      notifyListeners();
    } on Object {
      _errorMessage = 'Não foi possível atualizar seu perfil.';
      _status = previousStatus == InitialSetupStatus.completed
          ? previousStatus
          : InitialSetupStatus.completed;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createCategory({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int colorValue,
  }) async {
    await _manageCategory(() async {
      if (await _repository.categoryNameExists(name: name)) {
        throw ArgumentError('Já existe uma categoria com esse nome.');
      }
      await _repository.createCategory(
        name: name,
        iconCodePoint: iconCodePoint,
        iconFontFamily: iconFontFamily,
        colorValue: colorValue,
      );
      _categories = List.of(await _repository.getCategories());
      _sortCategories();
    });
  }

  Future<void> updateCategory({required ExpenseCategory category}) async {
    await _manageCategory(() async {
      if (await _repository.categoryNameExists(
        name: category.name,
        excludingId: category.id,
      )) {
        throw ArgumentError('Já existe uma categoria com esse nome.');
      }
      final updated = await _repository.updateCategory(category: category);
      final index = _categories.indexWhere((item) => item.id == updated.id);
      if (index < 0) {
        throw StateError('Categoria não encontrada.');
      }
      _categories[index] = updated;
      _sortCategories();
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _manageCategory(() async {
      await _repository.deleteCategory(categoryId);
      _categories.removeWhere((category) => category.id == categoryId);
    });
  }

  Future<void> _manageCategory(Future<void> Function() operation) async {
    _isManagingCategory = true;
    _categoryErrorMessage = null;
    notifyListeners();
    try {
      await operation();
      notifyListeners();
    } on Object catch (error) {
      _categoryErrorMessage = error is ArgumentError
          ? error.message?.toString()
          : error is StateError
          ? error.message
          : 'Não foi possível gerenciar a categoria.';
      notifyListeners();
      rethrow;
    } finally {
      _isManagingCategory = false;
      notifyListeners();
    }
  }

  void _sortCategories() {
    _categories.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }
}
