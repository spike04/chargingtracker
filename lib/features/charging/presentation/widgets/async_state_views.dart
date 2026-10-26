import 'package:flutter/material.dart';

import 'empty_state.dart';

class ChargingLoadingView extends StatelessWidget {
  const ChargingLoadingView({
    required this.title,
    this.message = 'Loading your charging history...',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(titleSpacing: 16, title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChargingErrorView extends StatelessWidget {
  const ChargingErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(titleSpacing: 16, title: Text(title)),
    body: EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load data',
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    ),
  );
}
