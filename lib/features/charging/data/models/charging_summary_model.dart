import '../../domain/entities/charging_summary.dart';

class ChargingSummaryModel {
  const ChargingSummaryModel({
    required this.totalSessions,
    required this.fastCount,
    required this.slowCount,
    required this.totalPercentageAdded,
    required this.lastChargedAt,
    required this.totalEnergyKwh,
    required this.totalCost,
  });

  factory ChargingSummaryModel.fromMap(Map<String, Object?> map) {
    final lastChargedAt = map['last_charged_at'];

    return ChargingSummaryModel(
      totalSessions: _asInt(map['total_sessions']),
      fastCount: _asInt(map['fast_count']),
      slowCount: _asInt(map['slow_count']),
      totalPercentageAdded: _asInt(map['total_added']),
      lastChargedAt: lastChargedAt is num
          ? DateTime.fromMillisecondsSinceEpoch(lastChargedAt.toInt())
          : null,
      totalEnergyKwh: _asDouble(map['total_energy']),
      totalCost: _asDouble(map['total_cost']),
    );
  }

  final int totalSessions;
  final int fastCount;
  final int slowCount;
  final int totalPercentageAdded;
  final DateTime? lastChargedAt;
  final double totalEnergyKwh;
  final double totalCost;

  ChargingSummary toEntity() => ChargingSummary(
    totalSessions: totalSessions,
    fastCount: fastCount,
    slowCount: slowCount,
    totalPercentageAdded: totalPercentageAdded,
    lastChargedAt: lastChargedAt,
    totalEnergyKwh: totalEnergyKwh,
    totalCost: totalCost,
  );
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;
