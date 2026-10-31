import 'dart:ui';

import 'package:flutter/material.dart';

/// Translucent bar that blurs the content scrolling behind it and separates
/// itself with a hairline bottom border.
class FrostedBar extends StatelessWidget {
  const FrostedBar({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
