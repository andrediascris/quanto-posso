import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/providers/theme_provider.dart';
import 'package:quanto_posso/repositories/preferences_repository.dart';

class FakePreferencesRepository extends PreferencesRepository {
  FakePreferencesRepository({
    this.savedMode = ThemeMode.system,
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
    savedMode = ThemeMode.system;
  }
}

void main() {
  test('initialize carrega ThemeMode.system', () async {
    final provider = ThemeProvider(repository: FakePreferencesRepository());
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.system);
    expect(provider.status, ThemeStatus.ready);
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
    await provider.setThemeMode(ThemeMode.light);
    expect(provider.themeMode, ThemeMode.light);
    expect(repository.savedMode, ThemeMode.light);
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
    expect(provider.themeMode, ThemeMode.system);
    expect(
      provider.errorMessage,
      'Não foi possível salvar a preferência de tema.',
    );
  });

  test('erro ao carregar usa sistema e status error', () async {
    final provider = ThemeProvider(
      repository: FakePreferencesRepository(throwOnLoad: true),
    );
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.system);
    expect(provider.status, ThemeStatus.error);
    expect(
      provider.errorMessage,
      'Não foi possível carregar a preferência de tema.',
    );
  });
}
