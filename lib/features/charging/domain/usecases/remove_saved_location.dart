import 'package:injectable/injectable.dart';

import '../repositories/charging_repository.dart';

@lazySingleton
class RemoveSavedLocation {
  const RemoveSavedLocation(this._repository);

  final ChargingRepository _repository;

  Future<void> call(String location) => _repository.removeLocation(location);
}
