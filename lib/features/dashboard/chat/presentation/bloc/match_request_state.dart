// ─────────────────────────────────────────────────────────
//  bloc/match/match_request_state.dart
// ─────────────────────────────────────────────────────────
part of 'match_request_bloc.dart';

enum MatchRequestStatus { initial, loading, loaded, error }

class MatchRequestState extends Equatable {
  const MatchRequestState({
    this.status    = MatchRequestStatus.initial,
    this.requests  = const [],
    this.acceptedMatchId,
    this.acceptedUser,
    this.errorMessage,
    this.actingSwipeId,
  });

  final MatchRequestStatus status;
  final List<MatchRequest> requests;
  final String?            acceptedMatchId; // After accept → navigate to chat
  final UserModel?         acceptedUser;    // For chat screen params
  final String?            errorMessage;
  final String?            actingSwipeId;   // Which request is being acted on

  int get count => requests.length;

  MatchRequestState copyWith({
    MatchRequestStatus? status,
    List<MatchRequest>? requests,
    String?             acceptedMatchId,
    UserModel?          acceptedUser,
    String?             errorMessage,
    String?             actingSwipeId,
    bool                clearAccepted = false,
    bool                clearError    = false,
  }) => MatchRequestState(
    status:          status         ?? this.status,
    requests:        requests       ?? this.requests,
    acceptedMatchId: clearAccepted  ? null : (acceptedMatchId ?? this.acceptedMatchId),
    acceptedUser:    clearAccepted  ? null : (acceptedUser    ?? this.acceptedUser),
    errorMessage:    clearError     ? null : (errorMessage    ?? this.errorMessage),
    actingSwipeId:   actingSwipeId  ?? this.actingSwipeId,
  );

  @override
  List<Object?> get props => [status, requests, acceptedMatchId, errorMessage, actingSwipeId];
}
