import '../entities/charging_session.dart';
import '../entities/charging_summary.dart';

abstract interface class ChargingRepository {
  Future<List<ChargingSession>> getSessions();

  Future<ChargingSummary> getSummary();

  Future<void> addSession(ChargingSession session);

  Future<void> updateSession(ChargingSession session);

  Future<void> deleteSession(String id);
}
