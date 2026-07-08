// ─────────────────────────────────────────────────────────
//  ChallengeEvent
//  lib/bloc/challenge/challenge_event.dart
// ─────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();
  @override List<Object?> get props => [];
}

// Load active challenges list (Challenges Tab)
class ChallengesLoaded extends ChallengeEvent {
  const ChallengesLoaded({this.tier, this.city, this.type});
  final int?    tier;
  final String? city;
  final String? type;
  @override List<Object?> get props => [tier, city, type];
}

// Load detail for a single challenge
class ChallengeDetailLoaded extends ChallengeEvent {
  const ChallengeDetailLoaded(this.challengeId);
  final String challengeId;
  @override List<Object?> get props => [challengeId];
}

// Load the current user's active challenge entries
class MyChallengesLoaded extends ChallengeEvent {
  const MyChallengesLoaded();
}

// Join a challenge (solo or with buddy)
class ChallengeJoined extends ChallengeEvent {
  const ChallengeJoined(this.challengeId, {this.buddyId});
  final String  challengeId;
  final String? buddyId;
  @override List<Object?> get props => [challengeId, buddyId];
}

// Load the challenge proof feed
class ChallengeFeedLoaded extends ChallengeEvent {
  const ChallengeFeedLoaded(this.challengeId, {this.page = 1});
  final String challengeId;
  final int    page;
  @override List<Object?> get props => [challengeId, page];
}

// Submit proof for a station
class ChallengeProofSubmitted extends ChallengeEvent {
  const ChallengeProofSubmitted({
    required this.challengeId,
    required this.sessionId,
    required this.stationId,
    this.isCollab = false,
  });
  final String challengeId;
  final String sessionId;
  final String stationId;
  final bool   isCollab;
  @override List<Object?> get props => [challengeId, sessionId, stationId, isCollab];
}

// Add collab photo to an existing station proof
class CollabProofAdded extends ChallengeEvent {
  const CollabProofAdded({
    required this.challengeId,
    required this.stationCompletionId,
  });
  final String challengeId;
  final String stationCompletionId;
  @override List<Object?> get props => [challengeId, stationCompletionId];
}

// Load leaderboard
class LeaderboardLoaded extends ChallengeEvent {
  const LeaderboardLoaded({this.challengeId, this.city});
  final String? challengeId;
  final String? city;
  @override List<Object?> get props => [challengeId, city];
}

// Send a nudge to a buddy
class BuddyNudgeSent extends ChallengeEvent {
  const BuddyNudgeSent(this.buddyId);
  final String buddyId;
  @override List<Object?> get props => [buddyId];
}

// Clear any transient status (error/success) after showing it
class ChallengeStatusCleared extends ChallengeEvent {
  const ChallengeStatusCleared();
}
