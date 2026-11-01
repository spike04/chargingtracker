import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';
import '../bloc/charging_state.dart';
import '../utils/charging_home_widget.dart';
import '../widgets/add_session_sheet.dart';
import 'dashboard_page.dart';
import 'details_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  StreamSubscription<Uri?>? _widgetClicks;
  bool _isLogSheetOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<ChargingBloc>().add(const ChargingLoadRequested());

    if (ChargingHomeWidget.isSupported) {
      _widgetClicks = ChargingHomeWidget.clicks.listen(_onWidgetClicked);
      ChargingHomeWidget.initialClick().then(_onWidgetClicked);
    }
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  Future<void> _onWidgetClicked(Uri? uri) async {
    if (!mounted || _isLogSheetOpen || !ChargingHomeWidget.isLogCharge(uri)) {
      return;
    }

    _isLogSheetOpen = true;
    await openChargingSessionSheet(context);
    _isLogSheetOpen = false;
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ChargingBloc, ChargingState>(
        listenWhen: (previous, current) =>
            !identical(previous.sessions, current.sessions),
        listener: (context, state) => ChargingHomeWidget.update(state.sessions),
      ),
      BlocListener<ChargingBloc, ChargingState>(
        listenWhen: (previous, current) =>
            current.hasError &&
            previous.errorMessage != current.errorMessage &&
            current.sessions.isNotEmpty,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          context.read<ChargingBloc>().add(const ChargingErrorDismissed());
        },
      ),
    ],
    child: Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(onViewAll: () => setState(() => _selectedIndex = 1)),
          const DetailsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Details',
            ),
          ],
        ),
      ),
    ),
  );
}
