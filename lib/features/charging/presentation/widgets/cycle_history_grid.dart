import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_cycle.dart';
import '../../domain/entities/charging_session.dart';
import '../utils/charging_type_ui.dart';

/// A GitHub-contribution-style habit grid for charging sessions.
///
/// Layout rules
/// ─────────────
/// • One row = one cycle ([AppConstants.cycleLength] boxes, oldest first).
/// • Boxes fill left-to-right; each logged entry lights up the next box.
/// • Fast charge → teal hues, slow charge → amber hues.
/// • Shade is relative to the amount added in that session, so heavy charges
///   stand out from top-up charges at a glance.
/// • Every open slot of the current cycle shows the charge it is waiting for:
///   teal bolts for the fast slots, amber for the slow slot that closes the
///   cycle. The amber turns strong once the slow charge is due next.
/// • When the slow charge lands, the row fills, the cycle resets and the grid
///   moves forward one full row (5 boxes).
class CycleHistoryGrid extends StatelessWidget {
  const CycleHistoryGrid({
    required this.sessions,
    required this.cycle,
    required this.onLogCharge,
    super.key,
  });

  final List<ChargingSession> sessions;
  final ChargingCycle cycle;
  final VoidCallback onLogCharge;

  static const _cycleLen = AppConstants.cycleLength;
  static const _gap = 7.0;
  static const _actionWidth = 92.0;
  static const _actionGap = 12.0;
  static const _maxBoxSize = 46.0;
  static const _maxRows = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ordered = [...sessions]
      ..sort((a, b) => a.chargedAt.compareTo(b.chargedAt));

    final completedCycles = ordered.length ~/ _cycleLen;
    // Always keep the in-progress row visible, even when it is empty.
    final totalRows = completedCycles + 1;
    final shownRows = math.min(totalRows, _maxRows);
    final firstRow = totalRows - shownRows;
    final activeRow = totalRows - 1;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.radiusJumbo,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Charging pattern',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(completedCycles),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Legend(scheme: scheme),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                const gaps = _gap * (_cycleLen - 1);
                // Keep the action from squeezing the boxes on narrow screens.
                final actionWidth = math.min(
                  _actionWidth,
                  constraints.maxWidth * 0.3,
                );
                final room =
                    constraints.maxWidth - actionWidth - _actionGap - gaps;
                final boxSize = (room / _cycleLen).clamp(18.0, _maxBoxSize);

                return Column(
                  children: [
                    for (var row = firstRow; row < totalRows; row++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: row == totalRows - 1 ? 0 : 8,
                        ),
                        child: _CycleRow(
                          slots: _slotsForRow(ordered, row),
                          boxSize: boxSize,
                          actionWidth: actionWidth,
                          isActive: row == activeRow,
                          targetFast: cycle.targetFast,
                          onLogCharge: onLogCharge,
                          scheme: scheme,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (totalRows > _maxRows)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Showing the last $_maxRows of $totalRows cycles',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _NextUpHint(cycle: cycle, hasSessions: sessions.isNotEmpty),
          ],
        ),
      ),
    );
  }

  String _subtitle(int completedCycles) {
    if (sessions.isEmpty) return 'Each box is one logged charge';

    final cycleWord = completedCycles == 1 ? 'cycle' : 'cycles';
    return '$completedCycles $cycleWord complete · '
        '${cycle.total}/${cycle.targetTotal} this cycle';
  }

  List<ChargingSession?> _slotsForRow(List<ChargingSession> ordered, int row) {
    final start = row * _cycleLen;
    return List.generate(_cycleLen, (i) {
      final index = start + i;
      return index < ordered.length ? ordered[index] : null;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One cycle row (5 boxes + label)
// ─────────────────────────────────────────────────────────────────────────────
class _CycleRow extends StatelessWidget {
  const _CycleRow({
    required this.slots,
    required this.boxSize,
    required this.actionWidth,
    required this.isActive,
    required this.targetFast,
    required this.onLogCharge,
    required this.scheme,
  });

  final List<ChargingSession?> slots;
  final double boxSize;
  final double actionWidth;
  final bool isActive;
  final int targetFast;
  final VoidCallback onLogCharge;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final filledCount = slots.where((slot) => slot != null).length;
    // The first open slot of the active cycle is the one to log right now.
    final nextIndex = isActive && filledCount < slots.length ? filledCount : -1;

    return Row(
      children: [
        for (var i = 0; i < slots.length; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == slots.length - 1 ? 0 : CycleHistoryGrid._gap,
            ),
            child: _ChargeBox(
              session: slots[i],
              // Open slots show what belongs in them: the first [targetFast]
              // slots take a fast charge, the rest close the cycle slowly.
              hintType: isActive && slots[i] == null
                  ? (i < targetFast ? ChargingType.fast : ChargingType.slow)
                  : null,
              isNext: i == nextIndex,
              size: boxSize,
              scheme: scheme,
            ),
          ),
        const SizedBox(width: CycleHistoryGrid._actionGap),
        SizedBox(
          width: actionWidth,
          child: isActive
              ? _LogChargeButton(onPressed: onLogCharge)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual box
// ─────────────────────────────────────────────────────────────────────────────
class _ChargeBox extends StatelessWidget {
  const _ChargeBox({
    required this.session,
    required this.hintType,
    required this.isNext,
    required this.size,
    required this.scheme,
  });

  final ChargingSession? session;
  final ChargingType? hintType;
  final bool isNext;
  final double size;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final filled = session;

    if (filled == null) {
      return _EmptyBox(
        size: size,
        scheme: scheme,
        hintType: hintType,
        isNext: isNext,
      );
    }

    final color = _tint(filled.type.color(scheme), filled.addedPercentage);

    return Tooltip(
      message:
          '${filled.type.label} charge · +${filled.addedPercentage}%\n'
          '${AppDateFormatter.dateTime(filled.chargedAt)}',
      waitDuration: const Duration(milliseconds: 350),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(
            color: filled.type.color(scheme).withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            filled.type.icon,
            size: size * 0.44,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }

  /// Relative shade: heavier charges are brighter, top-ups are faint.
  Color _tint(Color base, int addedPercentage) {
    final level = switch (addedPercentage) {
      >= 60 => 1.0,
      >= 35 => 0.82,
      >= 18 => 0.6,
      _ => 0.38,
    };
    return Color.lerp(base.withValues(alpha: 0.38), base, level)!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty slot — shows the charge that belongs in it. Fast slots carry a faint
// teal bolt, the slow slot that closes the cycle carries amber, which turns
// strong once the slow charge is the one that is due.
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.size,
    required this.scheme,
    required this.hintType,
    required this.isNext,
  });

  final double size;
  final ColorScheme scheme;
  final ChargingType? hintType;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final hint = hintType;
    final accent = hint?.color(scheme);
    final isSlowDue = isNext && hint == ChargingType.slow;

    final fill = accent == null
        ? scheme.onSurface.withValues(alpha: 0.04)
        : accent.withValues(alpha: isSlowDue ? 0.22 : (isNext ? 0.16 : 0.08));
    final border = accent == null
        ? scheme.onSurface.withValues(alpha: 0.16)
        : accent.withValues(alpha: isSlowDue ? 0.7 : (isNext ? 0.45 : 0.28));

    final box = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: border,
          radius: size * 0.24,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: accent == null
              ? null
              : Center(
                  child: Icon(
                    hint!.icon,
                    size: size * 0.4,
                    color: accent.withValues(alpha: isNext ? 0.9 : 0.55),
                  ),
                ),
        ),
      ),
    );

    if (hint == null) return box;

    return Tooltip(
      message: isNext
          ? '${hint.label} charge needed next'
          : '${hint.label} charge slot',
      waitDuration: const Duration(milliseconds: 350),
      child: box,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log-charge action (right of the active row)
// ─────────────────────────────────────────────────────────────────────────────
class _LogChargeButton extends StatelessWidget {
  const _LogChargeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Log charge', maxLines: 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer: what to log next
// ─────────────────────────────────────────────────────────────────────────────
class _NextUpHint extends StatelessWidget {
  const _NextUpHint({required this.cycle, required this.hasSessions});

  final ChargingCycle cycle;
  final bool hasSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (IconData icon, String message, Color color) = _hint(scheme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  (IconData, String, Color) _hint(ColorScheme scheme) {
    if (!hasSessions) {
      return (
        Icons.grid_view_rounded,
        'Log five charges to complete a cycle — the slow one closes it.',
        scheme.onSurfaceVariant,
      );
    }

    if (cycle.isComplete) {
      return (
        Icons.restart_alt_rounded,
        'Cycle ${cycle.cycleNumber - 1} complete — cycle ${cycle.cycleNumber} '
            'needs ${cycle.targetFast} fast charges, then a slow one.',
        scheme.primary,
      );
    }

    if (cycle.needsFast) {
      final remaining = cycle.targetFast - cycle.fastCount;
      return (
        ChargingType.fast.icon,
        '$remaining more fast ${remaining == 1 ? 'charge' : 'charges'} '
            'before the slow one.',
        ChargingType.fast.color(scheme),
      );
    }

    return (
      ChargingType.slow.icon,
      'Slow charge next to close cycle ${cycle.cycleNumber}.',
      ChargingType.slow.color(scheme),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend
// ─────────────────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  const _Legend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: ChargingType.fast.color(scheme)),
        const SizedBox(width: 4),
        Text('Fast', style: theme.textTheme.labelSmall),
        const SizedBox(width: 10),
        _LegendDot(color: ChargingType.slow.color(scheme)),
        const SizedBox(width: 4),
        Text('Slow', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed border painter for open slots
// ─────────────────────────────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    const dashLen = 4.0;
    const gapLen = 3.0;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final total = metrics.length;

    var dist = 0.0;
    while (dist < total) {
      final end = (dist + dashLen).clamp(0.0, total);
      canvas.drawPath(metrics.extractPath(dist, end), paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
