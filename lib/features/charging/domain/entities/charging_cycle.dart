import '../../../../core/constants/app_constants.dart';
import 'charging_session.dart';

/// The cycle currently in progress.
///
/// A cycle is a run of fast charges closed by a slow charge. Cycles are worked
/// out from the session history each time, so nothing about them is stored.
class ChargingCycle {
  const ChargingCycle({
    required this.fastCount,
    required this.targetFast,
    required this.cycleNumber,
    required this.isComplete,
  });

  factory ChargingCycle.fromSessions(
    List<ChargingSession> sessions, {
    int targetFast = AppConstants.targetFastCharges,
  }) {
    final cycles = group(sessions);
    final completedCycles = cycles.length - 1;
    final current = cycles.last;

    return ChargingCycle(
      fastCount: current.length,
      targetFast: targetFast,
      cycleNumber: completedCycles + 1,
      isComplete: current.isEmpty && completedCycles > 0,
    );
  }

  /// Splits [sessions] into cycles, oldest first.
  ///
  /// Every slow charge closes its cycle, however many fast charges came before
  /// it. The last entry is always the open cycle, which is empty right after a
  /// slow charge and only ever holds fast charges.
  static List<List<ChargingSession>> group(List<ChargingSession> sessions) {
    final ordered = [...sessions]
      ..sort((a, b) {
        final byChargedAt = a.chargedAt.compareTo(b.chargedAt);
        return byChargedAt != 0
            ? byChargedAt
            : a.createdAt.compareTo(b.createdAt);
      });

    final cycles = <List<ChargingSession>>[[]];
    for (final session in ordered) {
      cycles.last.add(session);
      if (session.type == ChargingType.slow) {
        cycles.add([]);
      }
    }

    return cycles;
  }

  final int fastCount;
  final int targetFast;
  final int cycleNumber;

  /// True right after a slow charge, before the next cycle has any charges.
  final bool isComplete;

  bool get needsFast => fastCount < targetFast;

  /// Fast charges left before the slow charge is due.
  int get fastRemaining => needsFast ? targetFast - fastCount : 0;
}
