// ─────────────────────────────────────────────────────────
//  bloc/match/match_request_event.dart
// ─────────────────────────────────────────────────────────
part of 'match_request_bloc.dart';

abstract class MatchRequestEvent extends Equatable {
  const MatchRequestEvent();
  @override List<Object?> get props => [];
}

// Load all pending match requests
class MatchRequestsLoaded extends MatchRequestEvent {
  const MatchRequestsLoaded();
}

// Accept a request
class MatchRequestAccepted extends MatchRequestEvent {
  const MatchRequestAccepted({ required this.swipeId, required this.user });
  final String    swipeId;
  final UserModel user;
  @override List<Object?> get props => [swipeId];
}

// Decline a request
class MatchRequestDeclined extends MatchRequestEvent {
  const MatchRequestDeclined({ required this.swipeId });
  final String swipeId;
  @override List<Object?> get props => [swipeId];
}
