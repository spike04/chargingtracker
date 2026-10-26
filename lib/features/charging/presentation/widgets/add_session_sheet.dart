import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/charging_session.dart';
import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';
import '../bloc/charging_state.dart';
import '../utils/charging_type_ui.dart';

Future<bool?> showChargingSessionSheet(
  BuildContext context, {
  ChargingSession? session,
  DateTime? initialDate,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) => BlocProvider.value(
    value: context.read<ChargingBloc>(),
    child: _ChargingSessionSheet(
      session: session,
      initialDate: initialDate,
    ),
  ),
);

Future<void> openChargingSessionSheet(
  BuildContext context, {
  ChargingSession? session,
  DateTime? initialDate,
}) async {
  final isEditing = session != null;
  final saved = await showChargingSessionSheet(
    context,
    session: session,
    initialDate: initialDate,
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing ? 'Charging session updated.' : 'Charging session saved.',
        ),
      ),
    );
  }
}

class _ChargingSessionSheet extends StatefulWidget {
  const _ChargingSessionSheet({this.session, this.initialDate});

  final ChargingSession? session;

  /// Day the entry should be logged against, used when the sheet is opened
  /// from a date picked in the calendar.
  final DateTime? initialDate;

  @override
  State<_ChargingSessionSheet> createState() => _ChargingSessionSheetState();
}

class _ChargingSessionSheetState extends State<_ChargingSessionSheet> {
  static const _locationSuggestions = [
    'Home',
    'Office',
    'Public charger',
    'Highway',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationController;
  late final TextEditingController _energyController;
  late final TextEditingController _costController;
  late ChargingType _type;
  late RangeValues _range;
  late DateTime _chargedAt;
  bool _isSubmitting = false;
  String? _rangeError;
  String? _submitError;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _locationController = TextEditingController(text: session?.location ?? '');
    _energyController = TextEditingController(
      text: _initialNumber(session?.energyKwh),
    );
    _costController = TextEditingController(
      text: _initialNumber(session?.cost),
    );
    _type = session?.type ?? ChargingType.fast;
    _range = RangeValues(
      (session?.startPercentage ?? 20).toDouble(),
      (session?.endPercentage ?? 80).toDouble(),
    );
    _chargedAt = session?.chargedAt ?? _defaultChargeDate();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _energyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  /// Seeds the sheet with the calendar's selected day at the current time,
  /// never in the future since a charge cannot be logged ahead of time.
  DateTime _defaultChargeDate() {
    final now = DateTime.now();
    final picked = widget.initialDate;
    if (picked == null) {
      return now;
    }

    final today = DateUtils.dateOnly(now);
    final day = DateUtils.dateOnly(picked);
    final clamped = day.isAfter(today) ? today : day;

    return DateTime(
      clamped.year,
      clamped.month,
      clamped.day,
      now.hour,
      now.minute,
    );
  }

  static String _initialNumber(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  static String? _validateOptionalNumber(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return 'Enter a number.';
    if (value < 0) return 'Cannot be negative.';
    return null;
  }

  void _setLocation(String location) {
    _locationController
      ..text = location
      ..selection = TextSelection.collapsed(offset: location.length);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chargedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
      helpText: 'Select charging date',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _chargedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _chargedAt.hour,
        _chargedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_chargedAt),
      helpText: 'Select charging time',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _chargedAt = DateTime(
        _chargedAt.year,
        _chargedAt.month,
        _chargedAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final start = _range.start.round();
    final end = _range.end.round();
    if (end <= start) {
      setState(() {
        _rangeError = 'The end level must be greater than the start level.';
      });
      return;
    }

    setState(() {
      _rangeError = null;
      _submitError = null;
      _isSubmitting = true;
    });

    final session = ChargingSession(
      id: widget.session?.id ?? const Uuid().v4(),
      startPercentage: start,
      endPercentage: end,
      type: _type,
      location: _locationController.text.trim(),
      chargedAt: _chargedAt,
      createdAt: widget.session?.createdAt ?? DateTime.now(),
      energyKwh: double.tryParse(_energyController.text.trim()),
      cost: double.tryParse(_costController.text.trim()),
    );

    final bloc = context.read<ChargingBloc>();
    if (_isEditing) {
      bloc.add(ChargingSessionUpdated(session));
    } else {
      bloc.add(ChargingSessionAdded(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final radius = isWide
        ? BorderRadius.circular(28)
        : const BorderRadius.vertical(top: Radius.circular(28));
    final added = _range.end.round() - _range.start.round();

    return BlocListener<ChargingBloc, ChargingState>(
      listenWhen: (previous, current) =>
          _isSubmitting && previous.isSaving && !current.isSaving,
      listener: (context, state) {
        if (state.hasError) {
          setState(() {
            _isSubmitting = false;
            _submitError = state.errorMessage;
          });
          return;
        }
        Navigator.of(context).pop(true);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: isWide ? 24 : 0,
          right: isWide ? 24 : 0,
          bottom: MediaQuery.viewInsetsOf(context).bottom + (isWide ? 24 : 0),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Material(
              color: scheme.surface,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Edit charging session'
                                        : 'Log charging session',
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditing
                                        ? 'Update the details of this entry.'
                                        : 'Keep your fast and slow charging balanced.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<ChargingType>(
                          expandedInsets: EdgeInsets.zero,
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: ChargingType.fast,
                              icon: Icon(ChargingType.fast.icon),
                              label: const Text('Fast'),
                            ),
                            ButtonSegment(
                              value: ChargingType.slow,
                              icon: Icon(ChargingType.slow.icon),
                              label: const Text('Slow'),
                            ),
                          ],
                          selected: {_type},
                          onSelectionChanged: (selection) {
                            setState(() => _type = selection.first);
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.32,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Battery level',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _type
                                          .color(scheme)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '+$added%',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: _type.color(scheme),
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_range.start.round()}%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${_range.end.round()}%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                          color: _type.color(scheme),
                                        ),
                                  ),
                                ],
                              ),
                              RangeSlider(
                                values: _range,
                                max: 100,
                                divisions: 100,
                                labels: RangeLabels(
                                  '${_range.start.round()}%',
                                  '${_range.end.round()}%',
                                ),
                                activeColor: _type.color(scheme),
                                onChanged: (values) {
                                  setState(() {
                                    _range = values;
                                    _rangeError = null;
                                  });
                                },
                              ),
                              if (_rangeError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    _rangeError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  AppDateFormatter.fullDate(_chargedAt),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                ),
                                label: Text(AppDateFormatter.time(_chargedAt)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text('Location', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'Where did you charge?',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) {
                            final location = value?.trim() ?? '';
                            if (location.isEmpty) {
                              return 'Please add a charging location.';
                            }
                            if (location.length < 2) {
                              return 'Location is too short.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _locationSuggestions
                              .map(
                                (location) => ActionChip(
                                  avatar: const Icon(
                                    Icons.add_location_alt_outlined,
                                    size: 16,
                                  ),
                                  label: Text(location),
                                  onPressed: () => _setLocation(location),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Energy & cost (optional)',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _energyController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Energy (kWh)',
                                  prefixIcon: Icon(Icons.bolt_outlined),
                                ),
                                validator: _validateOptionalNumber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (Rs)',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                validator: _validateOptionalNumber,
                              ),
                            ),
                          ],
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: scheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _submitError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      scheme.onPrimary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSubmitting
                                ? 'Saving...'
                                : _isEditing
                                ? 'Update session'
                                : 'Save session',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
