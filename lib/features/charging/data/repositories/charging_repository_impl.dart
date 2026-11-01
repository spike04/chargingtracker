import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/charging_session.dart';
import '../../domain/entities/charging_summary.dart';
import '../../domain/repositories/charging_repository.dart';
import '../datasources/charging_local_data_source.dart';
import '../models/charging_session_model.dart';

@LazySingleton(as: ChargingRepository)
class ChargingRepositoryImpl implements ChargingRepository {
  const ChargingRepositoryImpl(this._localDataSource);

  static const _backupApp = 'chargingtracker';
  static const _backupVersion = 1;

  final ChargingLocalDataSource _localDataSource;

  @override
  Future<List<ChargingSession>> getSessions() => _guard(() async {
    final models = await _localDataSource.fetchSessions();
    return models.map((model) => model.toEntity()).toList(growable: false);
  });

  @override
  Future<ChargingSummary> getSummary() => _guard(() async {
    final model = await _localDataSource.fetchSummary();
    return model.toEntity();
  });

  @override
  Future<void> addSession(ChargingSession session) => _guard(
    () => _localDataSource.insertSession(
      ChargingSessionModel.fromEntity(session),
    ),
  );

  @override
  Future<void> updateSession(ChargingSession session) => _guard(
    () => _localDataSource.updateSession(
      ChargingSessionModel.fromEntity(session),
    ),
  );

  @override
  Future<void> deleteSession(String id) =>
      _guard(() => _localDataSource.deleteSession(id));

  @override
  Future<List<String>> getLocations() =>
      _guard(_localDataSource.fetchLocations);

  @override
  Future<void> removeLocation(String location) =>
      _guard(() => _localDataSource.deleteLocation(location));

  @override
  Future<String> exportBackup() => _guard(() async {
    final sessions = await _localDataSource.fetchSessions();
    final locations = await _localDataSource.fetchLocations();

    return jsonEncode({
      'app': _backupApp,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': [for (final session in sessions) session.toMap()],
      'locations': locations,
    });
  });

  @override
  Future<int> importBackup(String backup) => _guard(() {
    final (:sessions, :locations) = _parseBackup(backup);
    return _localDataSource.insertMissing(sessions, locations);
  });

  /// Reads the whole backup up front, so a damaged file is rejected before
  /// anything is written.
  ({List<ChargingSessionModel> sessions, List<String> locations}) _parseBackup(
    String backup,
  ) {
    try {
      final data = jsonDecode(backup) as Map<String, Object?>;
      if (data['app'] != _backupApp || data['version'] != _backupVersion) {
        throw const FormatException();
      }

      final rows = (data['sessions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      final sessions = rows.map(ChargingSessionModel.fromMap).toList();
      for (var i = 0; i < rows.length; i++) {
        final isKnownType = rows[i]['charging_type'] == sessions[i].type.name;
        if (!isKnownType || !sessions[i].toEntity().isValid) {
          throw const FormatException();
        }
      }

      final locations = (data['locations']! as List<Object?>)
          .cast<String>()
          .toList();
      return (sessions: sessions, locations: locations);
    } catch (_) {
      throw const ValidationFailure('This is not a valid charging backup.');
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
