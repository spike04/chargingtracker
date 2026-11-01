import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/charging_session_model.dart';
import '../models/charging_summary_model.dart';
import 'charging_local_data_source.dart';

@LazySingleton(as: ChargingLocalDataSource)
class SqliteChargingLocalDataSource implements ChargingLocalDataSource {
  const SqliteChargingLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _database => _appDatabase.database;

  @override
  Future<List<ChargingSessionModel>> fetchSessions() async {
    final database = await _database;
    final rows = await database.query(
      AppConstants.sessionsTable,
      orderBy: 'charged_at DESC',
    );

    return rows.map(ChargingSessionModel.fromMap).toList(growable: false);
  }

  @override
  Future<ChargingSummaryModel> fetchSummary() async {
    final database = await _database;
    final rows = await database.rawQuery('''
      SELECT
        COUNT(*) AS total_sessions,
        COALESCE(SUM(CASE WHEN charging_type = 'fast' THEN 1 ELSE 0 END), 0)
          AS fast_count,
        COALESCE(SUM(CASE WHEN charging_type = 'slow' THEN 1 ELSE 0 END), 0)
          AS slow_count,
        COALESCE(SUM(end_percentage - start_percentage), 0) AS total_added,
        COALESCE(SUM(energy_kwh), 0) AS total_energy,
        COALESCE(SUM(cost), 0) AS total_cost,
        MAX(charged_at) AS last_charged_at
      FROM ${AppConstants.sessionsTable}
    ''');

    return ChargingSummaryModel.fromMap(rows.first);
  }

  @override
  Future<void> insertSession(ChargingSessionModel session) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.insert(
        AppConstants.sessionsTable,
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _rememberLocation(transaction, session.location);
    });
  }

  @override
  Future<void> updateSession(ChargingSessionModel session) async {
    final database = await _database;
    await database.transaction((transaction) async {
      final previous = await transaction.query(
        AppConstants.sessionsTable,
        columns: ['location'],
        where: 'id = ?',
        whereArgs: [session.id],
      );
      await transaction.update(
        AppConstants.sessionsTable,
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
      // Only a changed location is remembered, so editing an old session does
      // not bring back a location the user has removed.
      if (previous.isNotEmpty &&
          previous.first['location'] != session.location) {
        await _rememberLocation(transaction, session.location);
      }
    });
  }

  @override
  Future<void> deleteSession(String id) async {
    final database = await _database;
    await database.delete(
      AppConstants.sessionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<String>> fetchLocations() async {
    final database = await _database;
    final rows = await database.query(
      AppConstants.locationsTable,
      orderBy: 'name',
    );

    return rows.map((row) => row['name']! as String).toList(growable: false);
  }

  @override
  Future<void> deleteLocation(String location) async {
    final database = await _database;
    await database.delete(
      AppConstants.locationsTable,
      where: 'name = ?',
      whereArgs: [location],
    );
  }

  @override
  Future<int> insertMissing(
    List<ChargingSessionModel> sessions,
    List<String> locations,
  ) async {
    final database = await _database;
    return database.transaction((transaction) async {
      final before = await _countSessions(transaction);
      for (final session in sessions) {
        await transaction.insert(
          AppConstants.sessionsTable,
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      // Only the saved list counts, so a location removed before the backup
      // was made stays removed even though old sessions still mention it.
      for (final location in locations) {
        await _rememberLocation(transaction, location);
      }
      return await _countSessions(transaction) - before;
    });
  }

  Future<int> _countSessions(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery(
      'SELECT COUNT(*) AS total FROM ${AppConstants.sessionsTable}',
    );
    return rows.first['total']! as int;
  }

  Future<void> _rememberLocation(DatabaseExecutor executor, String location) =>
      executor.insert(AppConstants.locationsTable, {
        'name': location,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
}
