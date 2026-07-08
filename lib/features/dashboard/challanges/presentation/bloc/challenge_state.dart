// ─────────────────────────────────────────────────────────
//  ChallengeState
//  lib/bloc/challenge/challenge_state.dart
// ─────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

enum ChallengeStatus { initial, loading, success, error }

class ChallengeState extends Equatable {
  const ChallengeState({
    this.status            = ChallengeStatus.initial,
    this.challenges        = const [],
    this.myEntries         = const [],
    this.selectedChallenge,
    this.feedPosts         = const [],
    this.leaderboard       = const [],
    this.errorMessage,
    this.successMessage,
    this.isFeedLoading     = false,
    this.isJoining         = false,
    this.isSubmittingProof = false,
  });

  final ChallengeStatus      status;
  final List<Challenge>      challenges;
  final List<ChallengeEntry> myEntries;
  final Challenge?           selectedChallenge;
  final List<ChallengeFeedPost> feedPosts;
  final List<LeaderboardEntry>  leaderboard;
  final String?              errorMessage;
  final String?              successMessage;
  final bool                 isFeedLoading;
  final bool                 isJoining;
  final bool                 isSubmittingProof;

  ChallengeState copyWith({
    ChallengeStatus?          status,
    List<Challenge>?          challenges,
    List<ChallengeEntry>?     myEntries,
    Challenge?                selectedChallenge,
    List<ChallengeFeedPost>?  feedPosts,
    List<LeaderboardEntry>?   leaderboard,
    String?                   errorMessage,
    String?                   successMessage,
    bool?                     isFeedLoading,
    bool?                     isJoining,
    bool?                     isSubmittingProof,
    bool                      clearError   = false,
    bool                      clearSuccess = false,
  }) {
    return ChallengeState(
      status:            status            ?? this.status,
      challenges:        challenges        ?? this.challenges,
      myEntries:         myEntries         ?? this.myEntries,
      selectedChallenge: selectedChallenge ?? this.selectedChallenge,
      feedPosts:         feedPosts         ?? this.feedPosts,
      leaderboard:       leaderboard       ?? this.leaderboard,
      errorMessage:      clearError   ? null : (errorMessage   ?? this.errorMessage),
      successMessage:    clearSuccess ? null : (successMessage ?? this.successMessage),
      isFeedLoading:     isFeedLoading     ?? this.isFeedLoading,
      isJoining:         isJoining         ?? this.isJoining,
      isSubmittingProof: isSubmittingProof ?? this.isSubmittingProof,
    );
  }

  @override
  List<Object?> get props => [
    status, challenges, myEntries, selectedChallenge,
    feedPosts, leaderboard, errorMessage, successMessage,
    isFeedLoading, isJoining, isSubmittingProof,
  ];
}
