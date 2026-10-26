import '../models/charging_session_model.dart';
import '../models/charging_summary_model.dart';

abstract interface class ChargingLocalDataSource {
  Future<List<ChargingSessionModel>> fetchSessions();

  Future<ChargingSummaryModel> fetchSummary();

  Future<void> insertSession(ChargingSessionModel session);

  Future<void> updateSession(ChargingSessionModel session);

  Future<void> deleteSession(String id);
}
