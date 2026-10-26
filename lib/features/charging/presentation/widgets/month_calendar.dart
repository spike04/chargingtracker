import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_session.dart';

/// A compact month grid that marks every day with logged charges and keeps a
/// month-scoped stat line (charges, percentage added) above the grid.
///
/// Collapsed, only the week that holds the selected day (or today) is shown.
/// Swiping down expands the full month and swiping up collapses it again, the
/// same gesture Google Calendar uses.
///
/// Days are tappable so the caller can highlight the day and jump to its
/// entries. Future days stay inert because a charge cannot be logged ahead of
/// time.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    required this.month,
    required this.weekAnchor,
    required this.sessions,
    required this.expanded,
    required this.onMonthChanged,
    required this.onWeekChanged,
    required this.onDaySelected,
    required this.onExpandedChanged,
    required this.onTodayPressed,
    this.selectedDay,
    super.key,
  });

  /// Any date inside the month that should be displayed.
  final DateTime month;

  /// All sessions; only the ones inside [month] feed the dot markers and the
  /// month stat.
  final List<ChargingSession> sessions;

  /// Any date inside the week that is shown while collapsed.
  final DateTime weekAnchor;

  final DateTime? selectedDay;

  /// When false only one week is rendered; when true the whole month is.
  final bool expanded;

  /// Fired by the arrows in month view.
  final ValueChanged<DateTime> onMonthChanged;

  /// Fired by the arrows in week view with the first day of the target week.
  final ValueChanged<DateTime> onWeekChanged;

  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onTodayPressed;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const double _cellHeight = 34;

  /// A swipe has to travel this far, or end this fast, to change the state.
  static const double _dragDistance = 40;
  static const double _swipeVelocity = 120;

  double _draggedDistance = 0;

  MonthCalendar get _calendar => widget;

  static DateTime _startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday % 7);

  void _goToPreviousPeriod() {
    final month = widget.month;
    if (widget.expanded) {
      widget.onMonthChanged(DateTime(month.year, month.month - 1));
      return;
    }

    final anchor = widget.weekAnchor;
    widget.onWeekChanged(DateTime(anchor.year, anchor.month, anchor.day - 7));
  }

  void _goToNextPeriod() {
    final month = widget.month;
    if (widget.expanded) {
      widget.onMonthChanged(DateTime(month.year, month.month + 1));
      return;
    }

    final anchor = widget.weekAnchor;
    widget.onWeekChanged(DateTime(anchor.year, anchor.month, anchor.day + 7));
  }

  bool _canGoToNextPeriod(DateTime today) {
    if (widget.expanded) {
      return widget.month.year != today.year ||
          widget.month.month != today.month;
    }

    return _startOfWeek(widget.weekAnchor).isBefore(_startOfWeek(today));
  }

  void _onDragStart(DragStartDetails details) {
    _draggedDistance = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _draggedDistance += details.delta.dy;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dragged = _draggedDistance;
    _draggedDistance = 0;

    final wantsExpand = dragged > _dragDistance || velocity > _swipeVelocity;
    final wantsCollapse =
        dragged < -_dragDistance || velocity < -_swipeVelocity;

    if (wantsExpand && !_calendar.expanded) {
      _calendar.onExpandedChanged(true);
    } else if (wantsCollapse && _calendar.expanded) {
      _calendar.onExpandedChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final month = widget.month;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Sunday-first grid, matching the default date formatting locale.
    final leadingBlanks = DateTime(month.year, month.month).weekday % 7;
    final monthRowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    var monthCharges = 0;
    var monthAdded = 0;
    final chargesByDate = <DateTime, int>{};
    for (final session in widget.sessions) {
      final chargedAt = session.chargedAt;
      if (chargedAt.year == month.year && chargedAt.month == month.month) {
        monthCharges++;
        monthAdded += session.addedPercentage;
      }
      final date = DateUtils.dateOnly(chargedAt);
      chargesByDate[date] = (chargesByDate[date] ?? 0) + 1;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    // Collapsed, render the week that holds the week anchor, falling back to
    // the first week when the anchor lives outside the displayed month.
    final anchor = DateUtils.dateOnly(widget.weekAnchor);
    final anchorInMonth =
        anchor.year == month.year && anchor.month == month.month;
    final firstRow = widget.expanded
        ? 0
        : (anchorInMonth ? (leadingBlanks + anchor.day - 1) ~/ 7 : 0);
    final visibleRowCount = widget.expanded ? monthRowCount : 1;

    final showsCurrentPeriod = widget.expanded
        ? isCurrentMonth
        : DateUtils.isSameDay(_startOfWeek(anchor), _startOfWeek(today));
    final canGoToNextPeriod = _canGoToNextPeriod(today);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _MonthArrow(
                  tooltip: widget.expanded ? 'Previous month' : 'Previous week',
                  icon: Icons.chevron_left_rounded,
                  onPressed: _goToPreviousPeriod,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppDateFormatter.monthYear(month),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _monthStatLine(monthCharges, monthAdded),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!showsCurrentPeriod)
                  TextButton(
                    onPressed: widget.onTodayPressed,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Today'),
                  ),
                _MonthArrow(
                  tooltip: widget.expanded ? 'Next month' : 'Next week',
                  icon: Icons.chevron_right_rounded,
                  onPressed: canGoToNextPeriod ? _goToNextPeriod : null,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                for (final label in _weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    var row = firstRow;
                    row < firstRow + visibleRowCount;
                    row++
                  )
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          Expanded(
                            child: _buildDayCell(
                              context,
                              row * 7 + column - leadingBlanks + 1,
                              chargesByDate,
                              today,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthStatLine(int charges, int addedPercentage) {
    if (charges == 0) {
      return 'No charges this month';
    }

    final suffix = charges == 1 ? 'charge' : 'charges';
    return '$charges $suffix  ·  $addedPercentage% added';
  }

  Widget _buildDayCell(
    BuildContext context,
    int dayNumber,
    Map<DateTime, int> chargesByDate,
    DateTime today,
  ) {
    final month = widget.month;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // DateTime normalises out-of-range days, so the leading and trailing cells
    // of a row resolve to the neighbouring month.
    final date = DateTime(month.year, month.month, dayNumber);
    final isOutsideMonth = date.year != month.year || date.month != month.month;
    final chargeCount = isOutsideMonth ? 0 : (chargesByDate[date] ?? 0);
    final selectedDay = widget.selectedDay;
    final isSelected =
        selectedDay != null && DateUtils.isSameDay(selectedDay, date);
    final isToday = DateUtils.isSameDay(date, today);
    final isFuture = date.isAfter(today);

    final Color foreground;
    if (isSelected) {
      foreground = scheme.onPrimary;
    } else if (isFuture) {
      foreground = scheme.onSurfaceVariant.withValues(alpha: 0.35);
    } else if (isOutsideMonth) {
      foreground = scheme.onSurfaceVariant.withValues(alpha: 0.4);
    } else {
      foreground = scheme.onSurface;
    }

    final Color fill;
    if (isSelected) {
      fill = scheme.primary;
    } else if (isToday) {
      fill = scheme.primary.withValues(alpha: 0.12);
    } else {
      fill = Colors.transparent;
    }

    final dots = chargeCount > 3 ? 3 : chargeCount;
    final dotColor = isSelected ? scheme.onPrimary : scheme.primary;

    return SizedBox(
      height: _cellHeight,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Material(
          color: fill,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isToday && !isSelected
                ? BorderSide(color: scheme.primary.withValues(alpha: 0.55))
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: isFuture ? null : () => widget.onDaySelected(date),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${AppDateFormatter.fullDate(date)}, $chargeCount',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      height: 1.1,
                      fontWeight: isSelected || chargeCount > 0
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var dot = 0; dot < dots; dot++)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    iconSize: 20,
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
  );
}
