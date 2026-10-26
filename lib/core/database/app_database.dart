import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async => _database ??= await _openDatabase();

  Future<Database> _openDatabase() async {
    final databasePath = path.join(
      await getDatabasesPath(),
      AppConstants.databaseName,
    );

    return openDatabase(
      databasePath,
      version: AppConstants.databaseVersion,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE ${AppConstants.sessionsTable} (
            id TEXT PRIMARY KEY,
            start_percentage INTEGER NOT NULL,
            end_percentage INTEGER NOT NULL,
            charging_type TEXT NOT NULL,
            location TEXT NOT NULL,
            charged_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            energy_kwh REAL,
            cost REAL
          )
        ''');

        await database.execute('''
          CREATE INDEX idx_${AppConstants.sessionsTable}_charged_at
          ON ${AppConstants.sessionsTable} (charged_at DESC)
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE ${AppConstants.sessionsTable} '
            'ADD COLUMN energy_kwh REAL',
          );
          await database.execute(
            'ALTER TABLE ${AppConstants.sessionsTable} ADD COLUMN cost REAL',
          );
        }
      },
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
