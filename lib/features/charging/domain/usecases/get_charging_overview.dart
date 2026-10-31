import 'package:injectable/injectable.dart';

import '../entities/charging_session.dart';
import '../entities/charging_summary.dart';
import '../repositories/charging_repository.dart';

class ChargingOverview {
  const ChargingOverview({
    required this.sessions,
    required this.summary,
    required this.locations,
  });

  final List<ChargingSession> sessions;
  final ChargingSummary summary;
  final List<String> locations;
}

@lazySingleton
class GetChargingOverview {
  const GetChargingOverview(this._repository);

  final ChargingRepository _repository;

  Future<ChargingOverview> call() async {
    final sessions = await _repository.getSessions();
    final summary = await _repository.getSummary();
    final locations = await _repository.getLocations();

    return ChargingOverview(
      sessions: sessions,
      summary: summary,
      locations: locations,
    );
  }
}
