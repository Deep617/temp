import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../../../auth/data/response_ml/register_response.dart';

class StrikeRemoteDatasource {
  final DioClient _dio;

  StrikeRemoteDatasource(this._dio);


  Future<Response> uploadFile(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      'folder': 'strike',
    });
    final response = await _dio.post('/upload', data: form);

    return response;
  }


  // ── Strike 2 — Buddy Strike (Snap style) ─────────────────

  // Strike bhejo buddy ko (kabhi bhi)
  Future<Map<String, dynamic>> sendStrike({
    required String matchId,
    required String imageUrl,
    String? caption,
  }) async {
    final res = await _dio.post(
      '/strikes',
      data: {
        'matchId': matchId,
        'imageUrl': imageUrl,
        if (caption != null) 'caption': caption,
      },
    );
    return _data(res);
  }

  // Strike view karo — one-time, 5 min mein expire
  Future<BuddyStrike> viewStrike(String strikeId) async {
    final res = await _dio.post('/strikes/$strikeId/view');
    return BuddyStrike.fromJson(_data(res));
  }

  // Emoji react karo — 💪🔥😤🏆🤝😮
  Future<void> reactToStrike(String strikeId, String emoji) async {
    await _dio.post('/strikes/$strikeId/react', data: {'emoji': emoji});
  }

  // Mujhe kitni pending strikes hain (not yet viewed)
  Future<List<BuddyStrike>> getPendingStrikes({String? buddyId}) async {
    final res = await _dio.get('/strikes/pending', queryParameters: {
      if (buddyId != null && buddyId.isNotEmpty) 'buddyId': buddyId,
    },);
    final data = _data(res);
    return (data['strikes'] as List<dynamic>)
        .map((e) => BuddyStrike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Ek match ka current streak nikalo
  Future<Map<String, dynamic>> getStrikeStreak(String matchId) async {
    final res = await _dio.get('/strikes/streak/$matchId');
    return _data(res);
    // returns: { streak: 5, totalStrikes: 23, lastStrikeAt: '...' }
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
      message:
          (body is Map ? body['message'] as String? : null) ??
          'Unexpected response',
    );
  }
}
