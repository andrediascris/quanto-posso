import 'package:flutter/material.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

enum ThemeStatus { initial, loading, ready, error }

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({PreferencesRepository? repository})
    : _repository = repository ?? PreferencesRepository();

  final PreferencesRepository _repository;

  ThemeStatus _status = ThemeStatus.initial;
  ThemeMode _themeMode = ThemeMode.light;
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
      _themeMode = _supportedMode(await _repository.getThemeMode());
      _status = ThemeStatus.ready;
    } on Object {
      _themeMode = ThemeMode.light;
      _errorMessage = 'Não foi possível carregar a preferência de tema.';
      _status = ThemeStatus.error;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final supportedMode = _supportedMode(mode);
    if (supportedMode == _themeMode) {
      return;
    }

    final previousMode = _themeMode;
    _themeMode = supportedMode;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveThemeMode(supportedMode);
    } on Object {
      _themeMode = previousMode;
      _errorMessage = 'Não foi possível salvar a preferência de tema.';
      notifyListeners();
      rethrow;
    }
  }

  ThemeMode _supportedMode(ThemeMode mode) {
    return mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
