import 'package:injectable/injectable.dart';

import '../repositories/charging_repository.dart';

@lazySingleton
class ExportChargingBackup {
  const ExportChargingBackup(this._repository);

  final ChargingRepository _repository;

  /// Returns every session and saved location as backup JSON.
  Future<String> call() => _repository.exportBackup();
}
