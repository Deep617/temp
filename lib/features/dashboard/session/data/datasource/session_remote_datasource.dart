import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../response_ml/pending_proof_confirm.dart';
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

    final data = _data(res);
    return (data['sessions'] as List<dynamic>)
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutSession> uploadProof({
    required String sessionId,
    required String imagePath,
  }) async {
    final form = FormData.fromMap({
      // Stamped proof photos are PNG — keep the extension honest
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.toLowerCase().endsWith('.png') ? 'proof.png' : 'proof.jpg',
      ),
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
    // limit 100: with only page 1 (20) loaded, buddy no. 21+ could not be picked
    final res = await _dio.get('/match/buddies', queryParameters: {'page': page, 'limit': 100});
    final list = _data(res) as List<dynamic>;
    return list.map((e) => BuddyProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /sessions/:id/confirm → buddy confirms uploaded proof
  Future<Map<String, dynamic>> confirmProof(String sessionId) async {
    final res = await _dio.post('/sessions/$sessionId/confirm');
    return (_data(res) as Map<String, dynamic>?) ?? {};
  }

  /// POST /sessions/:id/on-my-way → tells the others I'm coming
  Future<void> onMyWay(String sessionId) async {
    await _dio.post('/sessions/$sessionId/on-my-way');
  }

  /// GET /sessions/pending-confirm → proofs waiting for my confirmation
  Future<List<PendingProofConfirm>> getPendingConfirmations() async {
    final res = await _dio.get('/sessions/pending-confirm');
    final data = _data(res) as Map<String, dynamic>? ?? {};
    return (data['sessions'] as List<dynamic>? ?? [])
        .map((e) => PendingProofConfirm.fromJson(e as Map<String, dynamic>))
        .toList();
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

  dynamic _data(Response res) {
    final body = res.data;
    if (body is Map && body['success'] == true) {
      return body['data'];
    }
    throw DioException(
      requestOptions: res.requestOptions,
      response:       res,
      type:           DioExceptionType.badResponse,
      message:        (body is Map ? body['message'] as String? : null) ?? 'Unexpected response',
    );
  }
}
