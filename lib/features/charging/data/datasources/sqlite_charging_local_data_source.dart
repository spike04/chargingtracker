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
    await database.insert(
      AppConstants.sessionsTable,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSession(ChargingSessionModel session) async {
    final database = await _database;
    await database.update(
      AppConstants.sessionsTable,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
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
}
