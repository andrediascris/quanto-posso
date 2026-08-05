import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/models/app_backup.dart';

void main() {
  final exportedAt = DateTime.utc(2026, 8, 5, 9, 15);
  AppBackup createBackup() => AppBackup(
    backupVersion: 1,
    appName: 'Quanto Posso',
    exportedAt: exportedAt,
    profile: const {'id': 1, 'name': 'Andr\u00e9'},
    categories: const [
      {'id': 'food', 'name': 'Alimenta\u00e7\u00e3o'},
    ],
    expenses: const [
      {'id': 1, 'amount': 25.5},
    ],
    preferences: const {'theme_mode': 'dark'},
  );

  test('toJson gera a estrutura correta', () {
    final json = createBackup().toJson();
    expect(json.keys, {
      'metadata',
      'profile',
      'categories',
      'expenses',
      'preferences',
    });
    expect(json['profile'], containsPair('name', 'Andr\u00e9'));
  });

  test('datas s\u00e3o salvas em ISO 8601', () {
    final metadata = createBackup().toJson()['metadata'];
    expect(metadata, isA<Map<String, Object?>>());
    expect(
      (metadata! as Map<String, Object?>)['exported_at'],
      exportedAt.toIso8601String(),
    );
  });

  test('fromJson reconstr\u00f3i backup v\u00e1lido', () {
    final restored = AppBackup.fromJson(createBackup().toJson());
    expect(restored.backupVersion, 1);
    expect(restored.appName, 'Quanto Posso');
    expect(restored.exportedAt, exportedAt);
    expect(restored.categories, hasLength(1));
  });

  test('backup_version ausente lan\u00e7a FormatException', () {
    final json = createBackup().toJson();
    final metadata = Map<String, Object?>.from(
      json['metadata']! as Map<String, Object?>,
    )..remove('backup_version');
    json['metadata'] = metadata;
    expect(() => AppBackup.fromJson(json), throwsFormatException);
  });

  test('app_name inv\u00e1lido lan\u00e7a FormatException', () {
    final json = createBackup().toJson();
    final metadata = Map<String, Object?>.from(
      json['metadata']! as Map<String, Object?>,
    )..['app_name'] = 'Outro app';
    json['metadata'] = metadata;
    expect(() => AppBackup.fromJson(json), throwsFormatException);
  });

  test('lista de categorias inv\u00e1lida lan\u00e7a FormatException', () {
    final json = createBackup().toJson()..['categories'] = 'inv\u00e1lido';
    expect(() => AppBackup.fromJson(json), throwsFormatException);
  });

  test('encode e decode preservam quantidades e dados principais', () {
    final encoded = jsonEncode(createBackup().toJson());
    final decoded = jsonDecode(encoded);
    expect(decoded, isA<Map<Object?, Object?>>());
    final restored = AppBackup.fromJson(
      Map<String, Object?>.from(decoded as Map<Object?, Object?>),
    );
    expect(restored.profile?['name'], 'Andr\u00e9');
    expect(restored.categories, hasLength(1));
    expect(restored.expenses, hasLength(1));
    expect(restored.preferences['theme_mode'], 'dark');
  });
}
