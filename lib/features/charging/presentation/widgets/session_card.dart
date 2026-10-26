import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_session.dart';
import '../utils/charging_type_ui.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    this.onEdit,
    this.horizontalPadding = 16,
    super.key,
  });

  final ChargingSession session;
  final VoidCallback? onEdit;

  /// The item spans the full width of its list; the inset lives here so the
  /// divider underneath can run edge to edge.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = session.type.color(scheme);

    return InkWell(
      onTap: onEdit,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(session.type.icon, color: color, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${session.type.label} charge',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              session.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        AppDateFormatter.relativeDateTime(session.chargedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${session.startPercentage}% → '
                        '${session.endPercentage}%',
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (session.energyKwh != null ||
                          session.cost != null) ...[
                        const SizedBox(height: 6),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (session.energyKwh != null)
                              Expanded(
                                child: _MetaLine(
                                  icon: Icons.bolt_outlined,
                                  text:
                                      '${NumberFormat.decimalPattern().format(session.energyKwh)}'
                                      ' kWh',
                                ),
                              ),
                            if (session.cost != null)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _MetaLine(
                                    icon: Icons.payments_outlined,
                                    text:
                                        'Rs ${NumberFormat.decimalPattern().format(session.cost)}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '+${session.addedPercentage}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
