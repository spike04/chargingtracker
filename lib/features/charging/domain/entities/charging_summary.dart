class ChargingSummary {
  const ChargingSummary({
    required this.totalSessions,
    required this.fastCount,
    required this.slowCount,
    required this.totalPercentageAdded,
    this.lastChargedAt,
    this.totalEnergyKwh = 0,
    this.totalCost = 0,
  });

  static const empty = ChargingSummary(
    totalSessions: 0,
    fastCount: 0,
    slowCount: 0,
    totalPercentageAdded: 0,
  );

  final int totalSessions;
  final int fastCount;
  final int slowCount;
  final int totalPercentageAdded;
  final DateTime? lastChargedAt;

  /// Sum of the energy logged across sessions, in kWh.
  final double totalEnergyKwh;

  /// Sum of the amounts paid across sessions, in NPR.
  final double totalCost;

  double get averagePercentageAdded =>
      totalSessions == 0 ? 0 : totalPercentageAdded / totalSessions;

  double get fastRatio => totalSessions == 0 ? 0 : fastCount / totalSessions;

  double get slowRatio => totalSessions == 0 ? 0 : slowCount / totalSessions;

  ChargingSummary copyWith({
    int? totalSessions,
    int? fastCount,
    int? slowCount,
    int? totalPercentageAdded,
    DateTime? lastChargedAt,
    double? totalEnergyKwh,
    double? totalCost,
  }) => ChargingSummary(
    totalSessions: totalSessions ?? this.totalSessions,
    fastCount: fastCount ?? this.fastCount,
    slowCount: slowCount ?? this.slowCount,
    totalPercentageAdded: totalPercentageAdded ?? this.totalPercentageAdded,
    lastChargedAt: lastChargedAt ?? this.lastChargedAt,
    totalEnergyKwh: totalEnergyKwh ?? this.totalEnergyKwh,
    totalCost: totalCost ?? this.totalCost,
  );
}
