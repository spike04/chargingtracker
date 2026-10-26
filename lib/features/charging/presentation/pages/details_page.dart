import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_session.dart';
import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';
import '../bloc/charging_state.dart';
import '../utils/refresh_charging_data.dart';
import '../widgets/add_session_sheet.dart';
import '../widgets/async_state_views.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_calendar.dart';
import '../widgets/session_card.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final ScrollController _scrollController = ScrollController();

  /// Keyed by day so a tapped date can scroll its entry group into view.
  final Map<DateTime, GlobalKey> _dayKeys = {};

  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  /// Day whose week is shown while the calendar is collapsed.
  late DateTime _weekAnchor;

  /// Collapsed shows just the focused week; swiping down opens the full month.
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateUtils.dateOnly(DateTime.now());
    _visibleMonth = DateTime(now.year, now.month);
    _weekAnchor = now;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Week to show once the calendar collapses: the selected day when it is in
  /// the visible month, otherwise today when that month is the current one, and
  /// the first of the month as the final fallback.
  DateTime _resolveWeekAnchor() {
    final selected = _selectedDay;
    if (selected != null &&
        selected.year == _visibleMonth.year &&
        selected.month == _visibleMonth.month) {
      return DateUtils.dateOnly(selected);
    }

    final today = DateUtils.dateOnly(DateTime.now());
    if (today.year == _visibleMonth.year &&
        today.month == _visibleMonth.month) {
      return today;
    }

    return DateTime(_visibleMonth.year, _visibleMonth.month);
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _visibleMonth = DateTime(month.year, month.month);
      _selectedDay = null;
      _weekAnchor = _resolveWeekAnchor();
    });
  }

  void _onWeekChanged(DateTime anchor) {
    setState(() {
      final day = DateUtils.dateOnly(anchor);
      _weekAnchor = day;
      _visibleMonth = DateTime(day.year, day.month);
    });
  }

  void _onTodayPressed() {
    final today = DateUtils.dateOnly(DateTime.now());

    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _weekAnchor = today;
      _selectedDay = today;
    });

    _scrollToDay(today);
  }

  void _onDaySelected(DateTime day) {
    final isReselect =
        _selectedDay != null && DateUtils.isSameDay(_selectedDay, day);

    setState(() {
      _selectedDay = isReselect ? null : day;
      _weekAnchor = DateUtils.dateOnly(day);
      _visibleMonth = DateTime(day.year, day.month);
    });

    if (!isReselect) {
      _scrollToDay(day);
    }
  }

  void _scrollToDay(DateTime day) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dayKeys[DateUtils.dateOnly(day)]?.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.02,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _isSelectedDay(DateTime day) =>
      _selectedDay != null && DateUtils.isSameDay(_selectedDay, day);

  List<Widget> _buildDayGroups(
    BuildContext context,
    List<ChargingSession> sessions,
  ) {
    final grouped = <DateTime, List<ChargingSession>>{};
    for (final session in sessions) {
      final day = DateUtils.dateOnly(session.chargedAt);
      grouped.putIfAbsent(day, () => <ChargingSession>[]).add(session);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final children = <Widget>[];

    for (final day in days) {
      children.add(
        KeyedSubtree(
          key: _dayKeys.putIfAbsent(day, GlobalKey.new),
          child: _DayHeader(
            day: day,
            count: grouped[day]!.length,
            isSelected: _isSelectedDay(day),
          ),
        ),
      );

      for (final session in grouped[day]!) {
        children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Dismissible(
                key: ValueKey('session-${session.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, session),
                onDismissed: (_) {
                  context.read<ChargingBloc>().add(
                    ChargingSessionDeleted(session.id),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                child: SessionCard(
                  session: session,
                  onEdit: () =>
                      openChargingSessionSheet(context, session: session),
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ],
          ),
        );
      }
    }

    return children;
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChargingBloc, ChargingState>(
    builder: (context, state) {
      if (state.status == ChargingStatus.initial ||
          (state.isLoading && state.sessions.isEmpty)) {
        return const ChargingLoadingView(title: 'Charging details');
      }

      if (state.status == ChargingStatus.failure && state.sessions.isEmpty) {
        return ChargingErrorView(
          title: 'Charging details',
          message:
              state.errorMessage ??
              'Your charging history could not be loaded.',
          onRetry: () =>
              context.read<ChargingBloc>().add(const ChargingLoadRequested()),
        );
      }

      final sessions = state.visibleSessions;

      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              openChargingSessionSheet(context, initialDate: _selectedDay),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Log charge'),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: MonthCalendar(
                      month: _visibleMonth,
                      weekAnchor: _weekAnchor,
                      sessions: state.sessions,
                      selectedDay: _selectedDay,
                      expanded: _isCalendarExpanded,
                      onMonthChanged: _onMonthChanged,
                      onWeekChanged: _onWeekChanged,
                      onDaySelected: _onDaySelected,
                      onTodayPressed: _onTodayPressed,
                      onExpandedChanged: (expanded) {
                        if (expanded == _isCalendarExpanded) {
                          return;
                        }
                        setState(() {
                          _isCalendarExpanded = expanded;
                          if (!expanded) {
                            _weekAnchor = _resolveWeekAnchor();
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => refreshChargingData(context),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 2, bottom: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _FilterBar(state: state),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _ListSummary(
                                state: state,
                                visibleCount: sessions.length,
                              ),
                            ),
                            if (sessions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 28),
                                child: _EmptyDetails(state: state),
                              )
                            else
                              ..._buildDayGroups(context, sessions),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<bool> _confirmDelete(
  BuildContext context,
  ChargingSession session,
) async {
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
      title: const Text('Delete session?'),
      content: Text(
        'This ${session.type.label.toLowerCase()} charge from '
        '${session.startPercentage}% to ${session.endPercentage}% at '
        '${session.location} will be permanently removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.count,
    required this.isSelected,
  });

  final DateTime day;
  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppDateFormatter.relativeDay(day),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? scheme.primary : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'charge' : 'charges'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final ChargingState state;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final filter in ChargingFilter.values)
        ChoiceChip(
          label: Text('${filter.label} ${filter.countIn(state)}'),
          selected: state.filter == filter,
          showCheckmark: false,
          onSelected: (_) {
            context.read<ChargingBloc>().add(ChargingFilterChanged(filter));
          },
        ),
    ],
  );
}

class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.state, required this.visibleCount});

  final ChargingState state;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$visibleCount '
              '${visibleCount == 1 ? 'session' : 'sessions'} shown',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${state.visiblePercentageAdded}% added',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetails extends StatelessWidget {
  const _EmptyDetails({required this.state});

  final ChargingState state;

  @override
  Widget build(BuildContext context) {
    final isFiltered = state.filter != ChargingFilter.all;
    final title = switch (state.filter) {
      ChargingFilter.all => 'No charging sessions yet',
      ChargingFilter.fast => 'No fast charges yet',
      ChargingFilter.slow => 'No slow charges yet',
    };
    final message = switch (state.filter) {
      ChargingFilter.all =>
        'Log your first charge to start building your history.',
      ChargingFilter.fast =>
        'Fast charging sessions will appear here once you log one.',
      ChargingFilter.slow =>
        'Slow charging sessions will appear here once you log one.',
    };

    return EmptyState(
      icon: Icons.ev_station_outlined,
      title: title,
      message: message,
      action: isFiltered
          ? OutlinedButton.icon(
              onPressed: () {
                context.read<ChargingBloc>().add(
                  const ChargingFilterChanged(ChargingFilter.all),
                );
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Show all sessions'),
            )
          : FilledButton.icon(
              onPressed: () => openChargingSessionSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log a charge'),
            ),
    );
  }
}

extension on ChargingFilter {
  String get label => switch (this) {
    ChargingFilter.all => 'All',
    ChargingFilter.fast => 'Fast',
    ChargingFilter.slow => 'Slow',
  };

  int countIn(ChargingState state) => switch (this) {
    ChargingFilter.all => state.summary.totalSessions,
    ChargingFilter.fast => state.summary.fastCount,
    ChargingFilter.slow => state.summary.slowCount,
  };
}
