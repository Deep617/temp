import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../response_ml/workout_session.dart';

class SessionRemoteDatasource {
  final DioClient _dio;

  SessionRemoteDatasource(this._dio);

  /// POST /sessions → WorkoutSession
  Future<WorkoutSession> scheduleSession({
    required List<String> buddyIds, // [] = solo, [id] = buddy, [id,id] = group
    required String activity,
    required DateTime scheduledAt,
    required int durationMins, // 45 | 60 | 90 | 120
    String? gymName,
    String? challengeId,
  }) async {
    final res = await _dio.post(
      '/sessions',
      data: {
        'buddyIds': buddyIds,
        'activity': activity,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'durationMins': durationMins,
        if (gymName != null) 'gymName': gymName,
        if (challengeId != null) 'challengeId': challengeId,
      },
    );
    return WorkoutSession.fromJson(_body(res)['data'] as Map<String, dynamic>);
  }

  Future<List<WorkoutSession>> getMySessions({
    String? status,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/sessions/my',
      queryParameters: {if (status != null) 'status': status, 'page': page},
    );
    return (_body(res)['data'] as List)
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutSession> uploadProof({
    required String sessionId,
    required String imagePath,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath, filename: 'proof.jpg'),
      'folder': 'proofs',
    });
    final uploadRes = await _dio.post('/upload', data: form);
    final imageUrl = uploadRes.data['data']['url'] as String;
    final res = await _dio.post(
      '/sessions/$sessionId/proof',
      data: {'proofImageUrl': imageUrl},
    );
    return WorkoutSession.fromJson(_body(res)['data'] as Map<String, dynamic>);
  }


  /// GET /match/buddies → List<BuddyProfile>
  Future<List<BuddyProfile>> getMyBuddies({int page = 1}) async {
    final res = await _dio.get('/match/buddies', queryParameters: {'page': page});
    final list = _body(res) as List<dynamic>;
    return list.map((e) => BuddyProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /sessions/:id/respond → confirm or decline invite
  Future<void> respondToSessionInvite(String sessionId, String action) async {
    await _dio.post('/sessions/$sessionId/respond', data: {'action': action});
  }

  Map<String, dynamic> _body(Response res) {
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res.data;
    }
    throw Exception(
      (res.data as Map<String, dynamic>?)?['message'] ?? 'Request failed',
    );
  }
}
