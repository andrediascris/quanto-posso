import 'package:flutter/material.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

enum ThemeStatus { initial, loading, ready, error }

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({PreferencesRepository? repository})
    : _repository = repository ?? PreferencesRepository();

  final PreferencesRepository _repository;

  ThemeStatus _status = ThemeStatus.initial;
  ThemeMode _themeMode = ThemeMode.system;
  String? _errorMessage;

  ThemeStatus get status => _status;
  ThemeMode get themeMode => _themeMode;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ThemeStatus.loading;

  Future<void> initialize() async {
    _status = ThemeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _themeMode = await _repository.getThemeMode();
      _status = ThemeStatus.ready;
    } on Object {
      _themeMode = ThemeMode.system;
      _errorMessage = 'Não foi possível carregar a preferência de tema.';
      _status = ThemeStatus.error;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }

    final previousMode = _themeMode;
    _themeMode = mode;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveThemeMode(mode);
    } on Object {
      _themeMode = previousMode;
      _errorMessage = 'Não foi possível salvar a preferência de tema.';
      notifyListeners();
      rethrow;
    }
  }
}
