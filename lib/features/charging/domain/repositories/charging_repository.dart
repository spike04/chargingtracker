import '../entities/charging_session.dart';
import '../entities/charging_summary.dart';

abstract interface class ChargingRepository {
  Future<List<ChargingSession>> getSessions();

  Future<ChargingSummary> getSummary();

  Future<void> addSession(ChargingSession session);

  Future<void> updateSession(ChargingSession session);

  Future<void> deleteSession(String id);

  Future<List<String>> getLocations();

  Future<void> removeLocation(String location);

  Future<String> exportBackup();

  /// Adds whatever [backup] holds that is not stored yet and returns the
  /// number of new sessions. Stored sessions are left exactly as they are.
  Future<int> importBackup(String backup);
}
