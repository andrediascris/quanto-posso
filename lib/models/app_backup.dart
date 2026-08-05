class AppBackup {
  const AppBackup({
    required this.backupVersion,
    required this.appName,
    required this.exportedAt,
    required this.profile,
    required this.categories,
    required this.expenses,
    required this.preferences,
  });

  final int backupVersion;
  final String appName;
  final DateTime exportedAt;
  final Map<String, Object?>? profile;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> expenses;
  final Map<String, Object?> preferences;

  Map<String, Object?> toJson() => {
    'metadata': <String, Object?>{
      'backup_version': backupVersion,
      'app_name': appName,
      'exported_at': exportedAt.toIso8601String(),
    },
    'profile': profile,
    'categories': categories,
    'expenses': expenses,
    'preferences': preferences,
  };

  factory AppBackup.fromJson(Map<String, Object?> json) {
    final metadata = _stringMap(json['metadata'], 'metadata');
    final backupVersion = metadata['backup_version'];
    if (backupVersion is! int) {
      throw const FormatException('backup_version inv\u00e1lido.');
    }

    final appName = metadata['app_name'];
    if (appName != 'Quanto Posso') {
      throw const FormatException('app_name inv\u00e1lido.');
    }

    final exportedAtValue = metadata['exported_at'];
    final exportedAt = exportedAtValue is String
        ? DateTime.tryParse(exportedAtValue)
        : null;
    if (exportedAt == null) {
      throw const FormatException('exported_at inv\u00e1lido.');
    }

    final profileValue = json['profile'];
    final profile = profileValue == null
        ? null
        : _stringMap(profileValue, 'profile');

    return AppBackup(
      backupVersion: backupVersion,
      appName: appName as String,
      exportedAt: exportedAt,
      profile: profile,
      categories: _mapList(json['categories'], 'categories'),
      expenses: _mapList(json['expenses'], 'expenses'),
      preferences: _stringMap(json['preferences'], 'preferences'),
    );
  }
}

Map<String, Object?> _stringMap(Object? value, String field) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$field inv\u00e1lido.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw FormatException('$field inv\u00e1lido.');
    }
    result[key] = entry.value;
  }
  return result;
}

List<Map<String, Object?>> _mapList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field inv\u00e1lido.');
  }
  return value.map((item) => _stringMap(item, field)).toList(growable: false);
}
