// ─────────────────────────────────────────────────────────
//  ChallengeBloc
//  lib/bloc/challenge/challenge_bloc.dart
//
//  Handles all V2 challenge logic:
//   - listing, detail, my-entries
//   - join (solo + buddy)
//   - proof submission + collab proof
//   - feed pagination
//   - leaderboard
//   - buddy nudge
// ─────────────────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../repositories/challenge_repository.dart';
import 'challenge_event.dart';
import 'challenge_state.dart';

class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  ChallengeBloc({required this.challengeRepository})
      : super(const ChallengeState()) {
    on<ChallengesLoaded>(_onChallengesLoaded);
    on<ChallengeDetailLoaded>(_onChallengeDetailLoaded);
    on<MyChallengesLoaded>(_onMyChallengesLoaded);
    on<ChallengeJoined>(_onChallengeJoined);
    on<ChallengeFeedLoaded>(_onChallengeFeedLoaded);
    on<ChallengeProofSubmitted>(_onChallengeProofSubmitted);
    on<CollabProofAdded>(_onCollabProofAdded);
    on<LeaderboardLoaded>(_onLeaderboardLoaded);
    on<BuddyNudgeSent>(_onBuddyNudgeSent);
    on<ChallengeStatusCleared>(_onStatusCleared);
  }

  final ChallengeRepository challengeRepository;

  Future<void> _onChallengesLoaded(
    ChallengesLoaded event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(state.copyWith(status: ChallengeStatus.loading));
    try {
      final challenges = await challengeRepository.getChallenges(
        tier: event.tier,
        city: event.city,
        type: event.type,
      );
      emit(state.copyWith(
        status:     ChallengeStatus.success,
        challenges: challenges,
      ));
    } catch (e) {
      emit(state.copyWith(
        status:       ChallengeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onChallengeDetailLoaded(
    ChallengeDetailLoaded event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(state.copyWith(status: ChallengeStatus.loading));
    try {
      final challenge = await challengeRepository.getChallenge(event.challengeId);
      emit(state.copyWith(
        status:            ChallengeStatus.success,
        selectedChallenge: challenge,
      ));
    } catch (e) {
      emit(state.copyWith(
        status:       ChallengeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMyChallengesLoaded(
    MyChallengesLoaded event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      final entries = await challengeRepository.getMyChallenges();
      emit(state.copyWith(myEntries: entries));
    } catch (_) {}
  }

  Future<void> _onChallengeJoined(
    ChallengeJoined event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(state.copyWith(isJoining: true));
    try {
      final entry = await challengeRepository.joinChallenge(
        event.challengeId,
        buddyId: event.buddyId,
      );
      // Update the selected challenge's myEntry
      final updated = state.selectedChallenge != null
          ? Challenge.fromJson({
              ...{
                'id':                 state.selectedChallenge!.id,
                'title':              state.selectedChallenge!.title,
                'description':        state.selectedChallenge!.description,
                'type':               state.selectedChallenge!.type,
                'tier':               state.selectedChallenge!.tier,
                'startAt':            state.selectedChallenge!.startAt.toIso8601String(),
                'endAt':              state.selectedChallenge!.endAt.toIso8601String(),
                'xpPool':             state.selectedChallenge!.xpPool,
                'entryLevelRequired': state.selectedChallenge!.entryLevelRequired,
                'trustRequired':      state.selectedChallenge!.trustRequired,
                'isActive':           state.selectedChallenge!.isActive,
                'participantCount':   state.selectedChallenge!.participantCount + 1,
                'myEntry': {
                  'id':             entry.id,
                  'challengeId':    entry.challengeId,
                  'userId':         entry.userId,
                  'buddyId':        entry.buddyId,
                  'status':         entry.status,
                  'currentStation': entry.currentStation,
                  'totalXpEarned':  entry.totalXpEarned,
                  'joinedAt':       entry.joinedAt.toIso8601String(),
                  'completions':    [],
                },
              }
            })
          : null;
      emit(state.copyWith(
        isJoining:         false,
        selectedChallenge: updated,
        successMessage:    event.buddyId != null
            ? 'Challenge started with your buddy!'
            : 'You joined the challenge!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isJoining:    false,
        errorMessage: 'Could not join challenge. ${e.toString()}',
      ));
    }
  }

  Future<void> _onChallengeFeedLoaded(
    ChallengeFeedLoaded event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(state.copyWith(isFeedLoading: true));
    try {
      final posts = await challengeRepository.getChallengeFeed(
        event.challengeId,
        page: event.page,
      );
      final combined = event.page == 1
          ? posts
          : [...state.feedPosts, ...posts];
      emit(state.copyWith(
        isFeedLoading: false,
        feedPosts:     combined,
      ));
    } catch (_) {
      emit(state.copyWith(isFeedLoading: false));
    }
  }

  Future<void> _onChallengeProofSubmitted(
    ChallengeProofSubmitted event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(state.copyWith(isSubmittingProof: true));
    try {
      await challengeRepository.submitProof(
        event.challengeId,
        sessionId: event.sessionId,
        stationId: event.stationId,
        isCollab:  event.isCollab,
      );
      // Reload detail to reflect new station completion
      final updated = await challengeRepository.getChallenge(event.challengeId);
      emit(state.copyWith(
        isSubmittingProof: false,
        selectedChallenge: updated,
        successMessage: event.isCollab
            ? 'Collab proof submitted! +${updated.myEntry?.totalXpEarned ?? 0} XP'
            : 'Proof submitted! Station progress updated.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmittingProof: false,
        errorMessage:      'Proof submission failed. ${e.toString()}',
      ));
    }
  }

  Future<void> _onCollabProofAdded(
    CollabProofAdded event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      await challengeRepository.addCollabProof(
        event.challengeId,
        stationCompletionId: event.stationCompletionId,
      );
      emit(state.copyWith(successMessage: 'Collab badge earned!'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLeaderboardLoaded(
    LeaderboardLoaded event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      final board = await challengeRepository.getLeaderboard(
        challengeId: event.challengeId,
        city:        event.city,
      );
      emit(state.copyWith(leaderboard: board));
    } catch (_) {}
  }

  Future<void> _onBuddyNudgeSent(
    BuddyNudgeSent event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      await challengeRepository.nudgeBuddy(event.buddyId);
      emit(state.copyWith(successMessage: 'Nudge sent!'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not send nudge.'));
    }
  }

  void _onStatusCleared(
    ChallengeStatusCleared event,
    Emitter<ChallengeState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
