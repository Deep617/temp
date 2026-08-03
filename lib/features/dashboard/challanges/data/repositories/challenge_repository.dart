// ─────────────────────────────────────────────────────────
//  ChallengeRepository
//  lib/repositories/challenge_repository.dart
//
//  All V2 challenge API calls. Mirrors the V2 API contracts
//  from the master product document exactly.
//  Called only by ChallengeBloc — never directly from UI.
// ─────────────────────────────────────────────────────────
import '../response_ml/challange_model.dart';

abstract class ChallengeRepository {
  ChallengeRepository();

  // GET /challenges?tier=&city=&type=
  Future<List<Challenge>> getChallenges({
    int? tier,
    String? city,
    String? type,
    String? environment,
  });

  // GET /challenges/:id  — detail + stations + leaderboard
  Future<Challenge> getChallenge(String id);

  // GET /challenges/my  — active entries for current user
  Future<List<ChallengeEntry>> getMyChallenges();

  // POST /challenges/:id/join  { buddyId? }
  Future<ChallengeEntry> joinChallenge(String id, {String? buddyId});

  // GET /challenges/:id/feed
  Future<List<ChallengeFeedPost>> getChallengeFeed(String id, {int page = 1});

  // POST /challenges/:id/proof  { sessionId, stationId, isCollab? }
  Future<Map<String, dynamic>> submitProof(
    String challengeId, {
    required String sessionId,
    required String stationId,
    bool isCollab = false,
  });

  // POST /challenges/:id/collab  { stationCompletionId }
  Future<void> addCollabProof(
    String challengeId, {
    required String stationCompletionId,
  });

  // POST /match/nudge/:buddyId
  Future<void> nudgeBuddy(String buddyId);

  // GET /leaderboard?challengeId=&city=
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? challengeId,
    String? city,
  });

  Future<List<GlobalLeaderboardEntry>> getGlobalLeaderboard({
    String period = 'alltime',
    String? city,
  }) ;


  // ── GLOBAL FEED ──────────────────────────────────────────
  /// GET /feed → List<ChallengeFeedPost> (last 24hrs, auto-expires)
  Future<List<ChallengeFeedPost>> getGlobalFeed() ;

  /// POST /feed → post challenge completion to feed
  Future<ChallengeFeedPost> postToFeed(Map<String, dynamic> data) ;


}
