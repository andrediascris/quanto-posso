import 'package:quanto_posso/models/app_backup.dart';

class BackupImportPreview {
  const BackupImportPreview({
    required this.backup,
    required this.fileName,
    required this.categoryCount,
    required this.expenseCount,
    required this.profileName,
    required this.monthlyIncome,
    required this.exportedAt,
  });

  final AppBackup backup;
  final String fileName;
  final int categoryCount;
  final int expenseCount;
  final String profileName;
  final double monthlyIncome;
  final DateTime exportedAt;

  bool get hasProfile => backup.profile != null;
  int get backupVersion => backup.backupVersion;
}
