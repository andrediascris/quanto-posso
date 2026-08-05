import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _databaseName = 'quanto_posso.db';
  static const _databaseVersion = 3;
  static const _profilesTable = 'profiles';
  static const _categoriesTable = 'categories';
  static const _expensesTable = 'expenses';

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database async {
    final openDatabase = _database;
    if (openDatabase != null) {
      return openDatabase;
    }

    final openingDatabase = _openingDatabase ??= _openDatabase();

    try {
      final database = await openingDatabase;
      _database = database;
      return database;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(databasesPath, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createProfilesTable(database);
        await _createCategoriesTable(database);
        await _createExpensesSchema(database);
      },
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createExpensesSchema(database);
    }
    if (oldVersion < 3) {
      await database.execute(
        'ALTER TABLE categories '
        'ADD COLUMN color_value INTEGER NOT NULL '
        'DEFAULT 4280097615',
      );
    }
  }

  Future<void> _createProfilesTable(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE $_profilesTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        monthly_income REAL NOT NULL CHECK(monthly_income > 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCategoriesTable(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE $_categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
          CHECK(is_default IN (0, 1)),
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createExpensesSchema(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS $_expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL CHECK(amount > 0),
        category_id TEXT NOT NULL,
        description TEXT,
        occurred_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(category_id)
          REFERENCES $_categoriesTable(id)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
      )
    ''');
    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_occurred_at
      ON $_expensesTable(occurred_at)
    ''');
    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category_id
      ON $_expensesTable(category_id)
    ''');
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}
