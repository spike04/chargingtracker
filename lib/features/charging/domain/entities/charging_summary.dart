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
}
