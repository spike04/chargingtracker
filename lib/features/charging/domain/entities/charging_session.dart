enum ChargingType {
  fast,
  slow;

  String get label => switch (this) {
    ChargingType.fast => 'Fast',
    ChargingType.slow => 'Slow',
  };
}

class ChargingSession {
  const ChargingSession({
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

  final String id;
  final int startPercentage;
  final int endPercentage;
  final ChargingType type;
  final String location;
  final DateTime chargedAt;
  final DateTime createdAt;

  /// Energy drawn during the session, in kWh (optional).
  final double? energyKwh;

  /// Amount paid for the session, in NPR (optional).
  final double? cost;

  int get addedPercentage => endPercentage - startPercentage;

  bool get isValid =>
      id.trim().isNotEmpty &&
      startPercentage >= 0 &&
      endPercentage <= 100 &&
      endPercentage > startPercentage &&
      location.trim().isNotEmpty;

  ChargingSession copyWith({
    String? id,
    int? startPercentage,
    int? endPercentage,
    ChargingType? type,
    String? location,
    DateTime? chargedAt,
    DateTime? createdAt,
    double? energyKwh,
    double? cost,
  }) => ChargingSession(
    id: id ?? this.id,
    startPercentage: startPercentage ?? this.startPercentage,
    endPercentage: endPercentage ?? this.endPercentage,
    type: type ?? this.type,
    location: location ?? this.location,
    chargedAt: chargedAt ?? this.chargedAt,
    createdAt: createdAt ?? this.createdAt,
    energyKwh: energyKwh ?? this.energyKwh,
    cost: cost ?? this.cost,
  );
}
