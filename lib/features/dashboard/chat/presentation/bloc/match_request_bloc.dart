// ─────────────────────────────────────────────────────────
//  bloc/match/match_request_bloc.dart
// ─────────────────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:seshlly/features/auth/domain/repositories/auth_repository.dart';

import '../../../../auth/data/response_ml/register_response.dart';
import '../../../../strike/data/repositories/strike_repository.dart';

part 'match_request_event.dart';
part 'match_request_state.dart';

class MatchRequestBloc extends Bloc<MatchRequestEvent, MatchRequestState> {
  MatchRequestBloc({ required AuthRepository api })
    : _api = api,
      super(const MatchRequestState()) {
    on<MatchRequestsLoaded>  (_onLoad);
    on<MatchRequestAccepted> (_onAccept);
    on<MatchRequestDeclined> (_onDecline);
  }

  final AuthRepository _api;

  Future<void> _onLoad(
    MatchRequestsLoaded event,
    Emitter<MatchRequestState> emit,
  ) async {
    emit(state.copyWith(status: MatchRequestStatus.loading, clearError: true));
    try {
      final list = await _api.getMatchRequests();
      emit(state.copyWith(
        status:   MatchRequestStatus.loaded,
        requests: list,
      ));
    } catch (e) {
      emit(state.copyWith(
        status:       MatchRequestStatus.error,
        errorMessage: 'Could not load requests',
      ));
    }
  }

  Future<void> _onAccept(
    MatchRequestAccepted event,
    Emitter<MatchRequestState> emit,
  ) async {
    emit(state.copyWith(actingSwipeId: event.swipeId));
    try {
      final res = await _api.acceptMatchRequest(event.swipeId);

      // Remove from list
      final updated = state.requests
          .where((r) => r.swipeId != event.swipeId)
          .toList();

      emit(state.copyWith(
        status:          MatchRequestStatus.loaded,
        requests:        updated,
        acceptedMatchId: res['matchId'] as String?,
        acceptedUser:    event.user,
        actingSwipeId:   '',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage:  'Failed to accept request',
        actingSwipeId: '',
        clearError:    false,
      ));
    }
  }

  Future<void> _onDecline(
    MatchRequestDeclined event,
    Emitter<MatchRequestState> emit,
  ) async {
    emit(state.copyWith(actingSwipeId: event.swipeId));
    try {
      await _api.declineMatchRequest(event.swipeId);
      final updated = state.requests
          .where((r) => r.swipeId != event.swipeId)
          .toList();
      emit(state.copyWith(
        requests:      updated,
        actingSwipeId: '',
      ));
    } catch (_) {
      emit(state.copyWith(actingSwipeId: ''));
    }
  }
}
