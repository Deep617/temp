import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../response_ml/challange_model.dart';

class ChallengeRemoteDatasource {
  final DioClient _dio;

  ChallengeRemoteDatasource(this._dio);


  // ══════════════════════════════════════════════════════
  //  V2 CHALLENGES  /api/v1/challenges
  // ══════════════════════════════════════════════════════

  Future<List<Challenge>> getChallenges(Map<String, dynamic> params) async {
    final res = await _dio.get('/challenges', queryParameters: params);
    final data = _data(res);
    return (data['challenges'] as List<dynamic>)
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Challenge> getChallenge(String id) async {
    final res = await _dio.get('/challenges/$id');
    return Challenge.fromJson(_data(res)['challenge'] as Map<String, dynamic>);
  }

  Future<List<ChallengeEntry>> getMyChallenges() async {
    final res = await _dio.get('/challenges/my');
    final data = _data(res);
    return (data['entries'] as List<dynamic>)
        .map((e) => ChallengeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeEntry> joinChallenge(String id, {String? buddyId}) async {
    final res = await _dio.post('/challenges/$id/join', data: {
      if (buddyId != null) 'buddyId': buddyId,
    });
    return ChallengeEntry.fromJson(
        _data(res)['entry'] as Map<String, dynamic>);
  }

  Future<List<ChallengeFeedPost>> getChallengeFeed(String id,
      {int page = 1}) async {
    final res = await _dio.get('/challenges/$id/feed',
        queryParameters: {'page': page, 'limit': 20});
    final data = _data(res);
    return (data['posts'] as List<dynamic>)
        .map((e) => ChallengeFeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> submitChallengeProof(String challengeId, {
    required String sessionId,
    required String stationId,
    bool isCollab = false,
  }) async {
    final res = await _dio.post('/challenges/$challengeId/proof', data: {
      'sessionId': sessionId,
      'stationId': stationId,
      'isCollab': isCollab,
    });
    return _data(res);
  }

  Future<void> addCollabProof(String challengeId,
      {required String stationCompletionId}) async {
    await _dio.post('/challenges/$challengeId/collab',
        data: {'stationCompletionId': stationCompletionId});
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    String? challengeId,
    String? city,
  }) async {
    final params = <String, dynamic>{};
    if (challengeId != null) params['challengeId'] = challengeId;
    if (city != null) params['city'] = city;
    final res = await _dio.get('/leaderboard', queryParameters: params);
    final data = _data(res);
    return (data['entries'] as List<dynamic>)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> nudgeBuddy(String buddyId) async {
    await _dio.post('/match/nudge/$buddyId');
  }

  dynamic _data(Response res) {
    final body = res.data;
    if (body is Map && body['success'] == true) {
      return body['data'];
    }
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      message: (body is Map ? body['message'] as String? : null) ??
          'Unexpected response',
    );
  }
}
