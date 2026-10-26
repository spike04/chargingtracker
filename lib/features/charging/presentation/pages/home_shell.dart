import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';
import '../bloc/charging_state.dart';
import 'dashboard_page.dart';
import 'details_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<ChargingBloc>().add(const ChargingLoadRequested());
  }

  @override
  Widget build(BuildContext context) =>
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
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardPage(
                onViewAll: () => setState(() => _selectedIndex = 1),
              ),
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
