import 'package:equatable/equatable.dart';

import '../../domain/entities/charging_session.dart';
import 'charging_state.dart';

sealed class ChargingEvent extends Equatable {
  const ChargingEvent();

  @override
  List<Object?> get props => const [];
}

final class ChargingLoadRequested extends ChargingEvent {
  const ChargingLoadRequested();
}

final class ChargingRefreshRequested extends ChargingEvent {
  const ChargingRefreshRequested();
}

final class ChargingSessionAdded extends ChargingEvent {
  const ChargingSessionAdded(this.session);

  final ChargingSession session;

  @override
  List<Object?> get props => [session];
}

final class ChargingSessionUpdated extends ChargingEvent {
  const ChargingSessionUpdated(this.session);

  final ChargingSession session;

  @override
  List<Object?> get props => [session];
}

final class ChargingSessionDeleted extends ChargingEvent {
  const ChargingSessionDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ChargingFilterChanged extends ChargingEvent {
  const ChargingFilterChanged(this.filter);

  final ChargingFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class ChargingErrorDismissed extends ChargingEvent {
  const ChargingErrorDismissed();
}
