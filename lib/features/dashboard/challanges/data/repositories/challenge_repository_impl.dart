// ─────────────────────────────────────────────────────────
//  ChallengeRepository
//  lib/repositories/challenge_repository.dart
//
//  All V2 challenge API calls. Mirrors the V2 API contracts
//  from the master product document exactly.
//  Called only by ChallengeBloc — never directly from UI.
// ─────────────────────────────────────────────────────────
import 'package:seshlly/features/dashboard/challanges/data/datasource/challenge_remote_datasource.dart';
import 'package:seshlly/features/dashboard/challanges/data/repositories/challenge_repository.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/errors/app_error.dart';
import '../response_ml/challange_model.dart';

class ChallengeRepositoryImpl extends BaseRepository
    implements ChallengeRepository {
  final ChallengeRemoteDatasource remote;

  ChallengeRepositoryImpl(this.remote, super.connectivity);

  // GET /challenges?tier=&city=&type=
  @override
  Future<List<Challenge>> getChallenges({
    int? tier,
    String? city,
    String? type,
    String? environment,
  }) async {
    final params = <String, dynamic>{};
    if (tier != null) params['tier'] = tier;
    if (city != null) params['city'] = city;
    if (type != null) params['type'] = type;
    if (environment != null) params['environment'] = environment;
    return remote.getChallenges(params).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // GET /challenges/:id  — detail + stations + leaderboard
  @override
  Future<Challenge> getChallenge(String id) async {
    return remote.getChallenge(id).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // GET /challenges/my  — active entries for current user
  @override
  Future<List<ChallengeEntry>> getMyChallenges() async {
    return remote.getMyChallenges().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // POST /challenges/:id/join  { buddyId? }
  Future<ChallengeEntry> joinChallenge(String id, {String? buddyId}) async {
    return remote.joinChallenge(id, buddyId: buddyId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // GET /challenges/:id/feed
  @override
  Future<List<ChallengeFeedPost>> getChallengeFeed(
    String id, {
    int page = 1,
  }) async {
    return remote.getChallengeFeed(id, page: page).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // POST /challenges/:id/proof  { sessionId, stationId, isCollab? }
  @override
  Future<Map<String, dynamic>> submitProof(
    String challengeId, {
    required String sessionId,
    required String stationId,
    bool isCollab = false,
  }) async {
    return remote
        .submitChallengeProof(
          challengeId,
          sessionId: sessionId,
          stationId: stationId,
        )
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  // POST /challenges/:id/collab  { stationCompletionId }
  @override
  Future<void> addCollabProof(
    String challengeId, {
    required String stationCompletionId,
  }) async {
    return remote
        .addCollabProof(challengeId, stationCompletionId: stationCompletionId)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  // GET /leaderboard?challengeId=&city=
  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? challengeId,
    String? city,
  }) async {
    return remote
        .getLeaderboard(challengeId: challengeId, city: city)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  // POST /match/nudge/:buddyId
  @override
  Future<void> nudgeBuddy(String buddyId) async {
    return remote.nudgeBuddy(buddyId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<List<GlobalLeaderboardEntry>> getGlobalLeaderboard({
    String period = 'alltime',
    String? city,
  }) async {
    return remote.getGlobalLeaderboard(period: period!, city: city).catchError((
      e,
    ) {
      throw AppError.fromException(e);
    });
  }
}
