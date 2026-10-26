import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecases/add_charging_session.dart';
import '../../domain/usecases/delete_charging_session.dart';
import '../../domain/usecases/get_charging_overview.dart';
import '../../domain/usecases/update_charging_session.dart';
import 'charging_event.dart';
import 'charging_state.dart';

@injectable
class ChargingBloc extends Bloc<ChargingEvent, ChargingState> {
  ChargingBloc(
    this._getOverview,
    this._addSession,
    this._updateSession,
    this._deleteSession,
  ) : super(const ChargingState()) {
    on<ChargingLoadRequested>(_onLoadRequested);
    on<ChargingRefreshRequested>(_onRefreshRequested);
    on<ChargingSessionAdded>(_onSessionAdded);
    on<ChargingSessionUpdated>(_onSessionUpdated);
    on<ChargingSessionDeleted>(_onSessionDeleted);
    on<ChargingFilterChanged>(_onFilterChanged);
    on<ChargingErrorDismissed>(_onErrorDismissed);
  }

  final GetChargingOverview _getOverview;
  final AddChargingSession _addSession;
  final UpdateChargingSession _updateSession;
  final DeleteChargingSession _deleteSession;

  Future<void> _onLoadRequested(
    ChargingLoadRequested event,
    Emitter<ChargingState> emit,
  ) async {
    emit(state.copyWith(status: ChargingStatus.loading, clearError: true));
    await _refresh(emit);
  }

  Future<void> _onRefreshRequested(
    ChargingRefreshRequested event,
    Emitter<ChargingState> emit,
  ) async {
    emit(state.copyWith(status: ChargingStatus.loading, clearError: true));
    await _refresh(emit);
  }

  Future<void> _onSessionAdded(
    ChargingSessionAdded event,
    Emitter<ChargingState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _addSession(event.session);
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: _messageFor(error)));
      return;
    }
    await _refresh(emit);
  }

  Future<void> _onSessionUpdated(
    ChargingSessionUpdated event,
    Emitter<ChargingState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _updateSession(event.session);
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: _messageFor(error)));
      return;
    }
    await _refresh(emit);
  }

  Future<void> _onSessionDeleted(
    ChargingSessionDeleted event,
    Emitter<ChargingState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _deleteSession(event.id);
    } catch (error) {
      emit(state.copyWith(isDeleting: false, errorMessage: _messageFor(error)));
      return;
    }
    await _refresh(emit);
  }

  void _onFilterChanged(
    ChargingFilterChanged event,
    Emitter<ChargingState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onErrorDismissed(
    ChargingErrorDismissed event,
    Emitter<ChargingState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _refresh(Emitter<ChargingState> emit) async {
    try {
      final overview = await _getOverview();
      emit(
        state.copyWith(
          status: ChargingStatus.loaded,
          sessions: overview.sessions,
          summary: overview.summary,
          isSaving: false,
          isDeleting: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: state.sessions.isEmpty
              ? ChargingStatus.failure
              : ChargingStatus.loaded,
          isSaving: false,
          isDeleting: false,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) => error is AppFailure
      ? error.message
      : 'Something went wrong. Please try again.';
}
