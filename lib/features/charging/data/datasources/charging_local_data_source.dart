import '../models/charging_session_model.dart';
import '../models/charging_summary_model.dart';

abstract interface class ChargingLocalDataSource {
  Future<List<ChargingSessionModel>> fetchSessions();

  Future<ChargingSummaryModel> fetchSummary();

  Future<void> insertSession(ChargingSessionModel session);

  Future<void> updateSession(ChargingSessionModel session);

  Future<void> deleteSession(String id);

  Future<List<String>> fetchLocations();

  Future<void> deleteLocation(String location);

  /// Inserts the [sessions] whose ids are not stored yet, plus [locations], in
  /// one transaction and returns how many sessions were added.
  Future<int> insertMissing(
    List<ChargingSessionModel> sessions,
    List<String> locations,
  );
}
