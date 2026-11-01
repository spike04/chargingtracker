import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../domain/usecases/export_charging_backup.dart';
import '../../domain/usecases/import_charging_backup.dart';
import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';

Future<void> exportChargingBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final backup = await getIt<ExportChargingBackup>()();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final location = await FilePicker.saveFile(
      dialogTitle: 'Save charging backup',
      fileName: 'charging-tracker-backup-$date.json',
      bytes: utf8.encode(backup),
      mimeType: 'application/json',
    );
    if (location != null) {
      _show(messenger, 'Backup saved.');
    }
  } catch (error) {
    _show(messenger, _messageFor(error, 'The backup could not be saved.'));
  }
}

Future<void> importChargingBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final bloc = context.read<ChargingBloc>();

  try {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose charging backup',
    );
    if (file == null) {
      return;
    }

    final added = await getIt<ImportChargingBackup>()(
      utf8.decode(await file.readAsBytes()),
    );
    bloc.add(const ChargingRefreshRequested());
    _show(
      messenger,
      added == 0
          ? 'No new sessions in this backup.'
          : 'Added $added new ${added == 1 ? 'session' : 'sessions'}.',
    );
  } catch (error) {
    _show(messenger, _messageFor(error, 'The backup could not be read.'));
  }
}

String _messageFor(Object error, String fallback) =>
    error is AppFailure ? error.message : fallback;

void _show(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
