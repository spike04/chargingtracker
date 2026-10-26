import '../../../../core/constants/app_constants.dart';
import 'charging_session.dart';

class ChargingCycle {
  const ChargingCycle({
    required this.fastCount,
    required this.slowCount,
    required this.targetFast,
    required this.targetSlow,
    required this.cycleNumber,
    required this.isComplete,
  });

  factory ChargingCycle.fromSessions(
    List<ChargingSession> sessions, {
    int targetFast = AppConstants.targetFastCharges,
    int targetSlow = AppConstants.targetSlowCharges,
  }) {
    final cycleLength = targetFast + targetSlow;
    final ordered = [...sessions]
      ..sort((a, b) => a.chargedAt.compareTo(b.chargedAt));

    if (ordered.isEmpty) {
      return ChargingCycle(
        fastCount: 0,
        slowCount: 0,
        targetFast: targetFast,
        targetSlow: targetSlow,
        cycleNumber: 1,
        isComplete: false,
      );
    }

    final completedCycles = ordered.length ~/ cycleLength;
    final remainder = ordered.length % cycleLength;
    // A cycle is "just completed" when the session count is an exact multiple
    // of cycleLength.  In that case the *next* cycle is fresh (0 sessions in),
    // so we show zeroed counts and bump the cycle number by one.
    final isComplete = remainder == 0;

    if (isComplete) {
      // The slow charge that just ended finished the cycle.  Show the user
      // that the counter has reset and they are starting cycle N+1.
      return ChargingCycle(
        fastCount: 0,
        slowCount: 0,
        targetFast: targetFast,
        targetSlow: targetSlow,
        cycleNumber: completedCycles + 1,
        isComplete: true,
      );
    }

    // In-progress cycle: slice only the sessions that belong to it.
    final startIndex = completedCycles * cycleLength;
    final currentSessions = ordered.skip(startIndex).take(cycleLength);

    var fastCount = 0;
    var slowCount = 0;
    for (final session in currentSessions) {
      switch (session.type) {
        case ChargingType.fast:
          fastCount++;
        case ChargingType.slow:
          slowCount++;
      }
    }

    return ChargingCycle(
      fastCount: fastCount,
      slowCount: slowCount,
      targetFast: targetFast,
      targetSlow: targetSlow,
      cycleNumber: completedCycles + 1,
      isComplete: false,
    );
  }

  final int fastCount;
  final int slowCount;
  final int targetFast;
  final int targetSlow;
  final int cycleNumber;
  final bool isComplete;

  int get total => fastCount + slowCount;

  int get targetTotal => targetFast + targetSlow;

  double get progress =>
      targetTotal == 0 ? 0 : (total / targetTotal).clamp(0, 1);

  double get fastProgress =>
      targetFast == 0 ? 0 : (fastCount / targetFast).clamp(0, 1);

  double get slowProgress =>
      targetSlow == 0 ? 0 : (slowCount / targetSlow).clamp(0, 1);

  bool get targetMet => fastCount >= targetFast && slowCount >= targetSlow;

  bool get needsFast => fastCount < targetFast;

  String get recommendation {
    if (isComplete) {
      // Cycle just completed and counter has reset — encourage starting fresh.
      return 'Cycle complete! Start fast charging for cycle $cycleNumber.';
    }
    if (needsFast) {
      return 'Fast charge recommended next.';
    }
    if (slowCount < targetSlow) {
      return 'Slow charge recommended next.';
    }
    return 'Target met — finish with a slow charge to complete the cycle.';
  }
}
