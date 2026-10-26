import '../../domain/entities/charging_session.dart';

class ChargingSessionModel {
  const ChargingSessionModel({
    required this.id,
    required this.startPercentage,
    required this.endPercentage,
    required this.type,
    required this.location,
    required this.chargedAt,
    required this.createdAt,
    this.energyKwh,
    this.cost,
  });

  factory ChargingSessionModel.fromEntity(ChargingSession session) =>
      ChargingSessionModel(
        id: session.id,
        startPercentage: session.startPercentage,
        endPercentage: session.endPercentage,
        type: session.type,
        location: session.location,
        chargedAt: session.chargedAt,
        createdAt: session.createdAt,
        energyKwh: session.energyKwh,
        cost: session.cost,
      );

  factory ChargingSessionModel.fromMap(Map<String, Object?> map) =>
      ChargingSessionModel(
        id: map['id'] as String,
        startPercentage: (map['start_percentage'] as num).toInt(),
        endPercentage: (map['end_percentage'] as num).toInt(),
        type: ChargingType.values.firstWhere(
          (type) => type.name == map['charging_type'],
          orElse: () => ChargingType.fast,
        ),
        location: map['location'] as String,
        chargedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['charged_at'] as num).toInt(),
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as num).toInt(),
        ),
        energyKwh: (map['energy_kwh'] as num?)?.toDouble(),
        cost: (map['cost'] as num?)?.toDouble(),
      );

  final String id;
  final int startPercentage;
  final int endPercentage;
  final ChargingType type;
  final String location;
  final DateTime chargedAt;
  final DateTime createdAt;
  final double? energyKwh;
  final double? cost;

  ChargingSession toEntity() => ChargingSession(
    id: id,
    startPercentage: startPercentage,
    endPercentage: endPercentage,
    type: type,
    location: location,
    chargedAt: chargedAt,
    createdAt: createdAt,
    energyKwh: energyKwh,
    cost: cost,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'start_percentage': startPercentage,
    'end_percentage': endPercentage,
    'charging_type': type.name,
    'location': location,
    'charged_at': chargedAt.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'energy_kwh': energyKwh,
    'cost': cost,
  };
}
