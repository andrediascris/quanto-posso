import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/providers/theme_provider.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePreferencesRepository extends PreferencesRepository {
  FakePreferencesRepository({
    this.savedMode = ThemeMode.light,
    this.throwOnLoad = false,
    this.throwOnSave = false,
  });

  ThemeMode savedMode;
  final bool throwOnLoad;
  final bool throwOnSave;
  int saveCount = 0;

  @override
  Future<ThemeMode> getThemeMode() async {
    if (throwOnLoad) throw StateError('Falha simulada');
    return savedMode;
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    saveCount++;
    if (throwOnSave) throw StateError('Falha simulada');
    savedMode = mode;
  }

  @override
  Future<void> clear() async {
    savedMode = ThemeMode.light;
  }
}

void main() {
  test('estado inicial e initialize usam ThemeMode.light', () async {
    final provider = ThemeProvider(repository: FakePreferencesRepository());
    expect(provider.themeMode, ThemeMode.light);
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.status, ThemeStatus.ready);
  });

  test('initialize converte preferência antiga system para light', () async {
    final provider = ThemeProvider(
      repository: FakePreferencesRepository(savedMode: ThemeMode.system),
    );
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.light);
  });

  test('initialize carrega tema salvo', () async {
    final provider = ThemeProvider(
      repository: FakePreferencesRepository(savedMode: ThemeMode.dark),
    );
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.dark);
  });

  test('setThemeMode atualiza e persiste', () async {
    final repository = FakePreferencesRepository();
    final provider = ThemeProvider(repository: repository);
    await provider.initialize();
    await provider.setThemeMode(ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);
    expect(repository.savedMode, ThemeMode.dark);

    final reinitializedProvider = ThemeProvider(repository: repository);
    await reinitializedProvider.initialize();
    expect(reinitializedProvider.themeMode, ThemeMode.dark);
  });

  test('modo igual não salva novamente', () async {
    final repository = FakePreferencesRepository(savedMode: ThemeMode.light);
    final provider = ThemeProvider(repository: repository);
    await provider.initialize();
    await provider.setThemeMode(ThemeMode.light);
    expect(repository.saveCount, 0);
  });

  test('erro ao salvar restaura modo anterior', () async {
    final provider = ThemeProvider(
      repository: FakePreferencesRepository(throwOnSave: true),
    );
    await provider.initialize();
    await expectLater(
      provider.setThemeMode(ThemeMode.dark),
      throwsA(isA<StateError>()),
    );
    expect(provider.themeMode, ThemeMode.light);
    expect(
      provider.errorMessage,
      'Não foi possível salvar a preferência de tema.',
    );
  });

  test('erro ao carregar usa tema claro e status error', () async {
    final provider = ThemeProvider(
      repository: FakePreferencesRepository(throwOnLoad: true),
    );
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.status, ThemeStatus.error);
    expect(
      provider.errorMessage,
      'Não foi possível carregar a preferência de tema.',
    );
  });

  test('repository interpreta system e valor inválido como light', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    expect(await PreferencesRepository().getThemeMode(), ThemeMode.light);

    SharedPreferences.setMockInitialValues({'theme_mode': 'invalido'});
    expect(await PreferencesRepository().getThemeMode(), ThemeMode.light);
  });

  test('repository persiste somente light ou dark', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PreferencesRepository();

    await repository.saveThemeMode(ThemeMode.system);
    var preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), 'light');

    await repository.saveThemeMode(ThemeMode.dark);
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), 'dark');
    expect(await PreferencesRepository().getThemeMode(), ThemeMode.dark);
  });
}
