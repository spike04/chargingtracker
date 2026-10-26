import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/charging_repository.dart';

@lazySingleton
class DeleteChargingSession {
  const DeleteChargingSession(this._repository);

  final ChargingRepository _repository;

  Future<void> call(String id) {
    if (id.trim().isEmpty) {
      throw const ValidationFailure('A session id is required.');
    }
    return _repository.deleteSession(id);
  }
}
