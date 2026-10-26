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
