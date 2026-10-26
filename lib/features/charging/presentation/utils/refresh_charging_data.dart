import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/charging_bloc.dart';
import '../bloc/charging_event.dart';

Future<void> refreshChargingData(BuildContext context) async {
  final bloc = context.read<ChargingBloc>();
  bloc.add(const ChargingRefreshRequested());
  await bloc.stream
      .firstWhere((state) => !state.isLoading)
      .timeout(const Duration(seconds: 8), onTimeout: () => bloc.state);
}
