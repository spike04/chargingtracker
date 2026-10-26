import 'package:equatable/equatable.dart';

import '../../domain/entities/charging_cycle.dart';
import '../../domain/entities/charging_session.dart';
import '../../domain/entities/charging_summary.dart';

enum ChargingStatus { initial, loading, loaded, failure }

enum ChargingFilter { all, fast, slow }

class ChargingState extends Equatable {
  const ChargingState({
    this.status = ChargingStatus.initial,
    this.sessions = const [],
    this.summary = ChargingSummary.empty,
    this.filter = ChargingFilter.all,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  final ChargingStatus status;
  final List<ChargingSession> sessions;
  final ChargingSummary summary;
  final ChargingFilter filter;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;

  bool get isLoading => status == ChargingStatus.loading;

  bool get hasError => errorMessage != null;

  ChargingCycle get cycle => ChargingCycle.fromSessions(sessions);

  List<ChargingSession> get visibleSessions => switch (filter) {
    ChargingFilter.all => sessions,
    ChargingFilter.fast =>
      sessions
          .where((session) => session.type == ChargingType.fast)
          .toList(growable: false),
    ChargingFilter.slow =>
      sessions
          .where((session) => session.type == ChargingType.slow)
          .toList(growable: false),
  };

  int get visiblePercentageAdded => visibleSessions.fold(
    0,
    (total, session) => total + session.addedPercentage,
  );

  ChargingState copyWith({
    ChargingStatus? status,
    List<ChargingSession>? sessions,
    ChargingSummary? summary,
    ChargingFilter? filter,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) => ChargingState(
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    summary: summary ?? this.summary,
    filter: filter ?? this.filter,
    isSaving: isSaving ?? this.isSaving,
    isDeleting: isDeleting ?? this.isDeleting,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    sessions,
    summary,
    filter,
    isSaving,
    isDeleting,
    errorMessage,
  ];
}
