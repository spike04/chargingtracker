import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_summary.dart';
import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';
import '../bloc/charging_state.dart';
import '../utils/refresh_charging_data.dart';
import '../widgets/add_session_sheet.dart';
import '../widgets/async_state_views.dart';
import '../widgets/cycle_history_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/session_card.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.onViewAll, super.key});

  final VoidCallback onViewAll;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChargingBloc, ChargingState>(
    builder: (context, state) {
      if (state.status == ChargingStatus.initial ||
          (state.isLoading && state.sessions.isEmpty)) {
        return const ChargingLoadingView(title: AppConstants.appName);
      }

      if (state.status == ChargingStatus.failure && state.sessions.isEmpty) {
        return ChargingErrorView(
          title: AppConstants.appName,
          message:
              state.errorMessage ??
              'Your charging history could not be loaded.',
          onRetry: () =>
              context.read<ChargingBloc>().add(const ChargingLoadRequested()),
        );
      }

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: SizedBox.expand(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          toolbarHeight: 76,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppConstants.appName),
              Text(
                '${AppDateFormatter.fullDate(DateTime.now())}  ·  '
                '${state.summary.totalSessions} sessions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state.isLoading
                  ? null
                  : () => context.read<ChargingBloc>().add(
                      const ChargingRefreshRequested(),
                    ),
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: RefreshIndicator(
              onRefresh: () => refreshChargingData(context),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontal = 16.0;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8, bottom: 110),
                        sliver: SliverList.list(
                          children: [
                            SizedBox(
                              height: MediaQuery.paddingOf(context).top + 8,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              child: CycleHistoryGrid(
                                sessions: state.sessions,
                                cycle: state.cycle,
                                onLogCharge: () =>
                                    openChargingSessionSheet(context),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              child: _SectionHeader(
                                title: 'At a glance',
                                subtitle: 'Your charging habits in numbers',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              child: _StatsGrid(summary: state.summary),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              child: _SectionHeader(
                                title: 'Recent activity',
                                subtitle: state.sessions.isEmpty
                                    ? 'Your latest sessions will show here'
                                    : 'Your most recent charging sessions',
                                action: TextButton(
                                  onPressed: onViewAll,
                                  child: const Text('View all'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (state.sessions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontal,
                                ),
                                child: SizedBox(
                                  height: 280,
                                  child: EmptyState(
                                    icon: Icons.ev_station_outlined,
                                    title: 'No charging sessions yet',
                                    message:
                                        'Log your first charge to start '
                                        'tracking your fast and slow cycles.',
                                  ),
                                ),
                              )
                            else
                              for (final session in state.sessions.take(3)) ...[
                                SessionCard(
                                  session: session,
                                  onEdit: () => openChargingSessionSheet(
                                    context,
                                    session: session,
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final ChargingSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <({String label, String value, IconData icon, Color color})>[
      (
        label: 'Total',
        value: '${summary.totalSessions}',
        icon: Icons.ev_station_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      (
        label: 'Fast',
        value: '${summary.fastCount}',
        icon: Icons.bolt_rounded,
        color: scheme.primary,
      ),
      (
        label: 'Slow',
        value: '${summary.slowCount}',
        icon: Icons.battery_charging_full_rounded,
        color: const Color(0xFFF59E0B),
      ),
      (
        label: 'Avg ${summary.averagePercentageAdded.toStringAsFixed(0)}%',
        value: '${summary.totalPercentageAdded}%',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF3B82F6),
      ),
      (
        label: 'Total spent',
        value: 'Rs ${NumberFormat.decimalPattern().format(summary.totalCost)}',
        icon: Icons.payments_rounded,
        color: const Color(0xFF22C55E),
      ),
      (
        label: 'Total energy',
        value:
            '${NumberFormat.decimalPattern().format(summary.totalEnergyKwh)}'
            ' kWh',
        icon: Icons.electric_meter_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Column(
      children: [
        _StatsRow(items: items.sublist(0, 4)),
        const SizedBox(height: 12),
        // The money and energy tiles get the whole second row.
        _StatsRow(items: items.sublist(4)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<({String label, String value, IconData icon, Color color})> items;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 72,
            child: StatCard(
              label: items[i].label,
              value: items[i].value,
              icon: items[i].icon,
              accent: items[i].color,
            ),
          ),
        ),
      ],
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}
