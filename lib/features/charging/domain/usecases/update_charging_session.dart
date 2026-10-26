import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/charging_session.dart';
import '../repositories/charging_repository.dart';

@lazySingleton
class UpdateChargingSession {
  const UpdateChargingSession(this._repository);

  final ChargingRepository _repository;

  Future<void> call(ChargingSession session) {
    if (!session.isValid) {
      throw const ValidationFailure(
        'Please provide valid battery levels and a location.',
      );
    }
    return _repository.updateSession(session);
  }
}
