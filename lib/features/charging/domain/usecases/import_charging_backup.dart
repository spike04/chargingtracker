import 'package:injectable/injectable.dart';

import '../repositories/charging_repository.dart';

@lazySingleton
class ImportChargingBackup {
  const ImportChargingBackup(this._repository);

  final ChargingRepository _repository;

  /// Adds the sessions in [backup] that are not stored yet and returns how
  /// many were added. Stored sessions are never changed or removed.
  Future<int> call(String backup) => _repository.importBackup(backup);
}
