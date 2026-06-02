import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/dio_client.dart';
import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../response_ml/workout_session.dart';

class SessionRemoteDatasource {
  final DioClient _dio;

  SessionRemoteDatasource(this._dio);

  // SESSIONS
  Future<WorkoutSession> scheduleSession({
    required String buddyId,
    required String activity,
    required DateTime scheduledAt,
    String? gymName,
  }) async {
    final res = await _dio.post(
      '/sessions',
      data: {
        'buddyId': buddyId,
        'activity': activity,
        'scheduledAt': scheduledAt.toIso8601String(),
        if (gymName != null) 'gymName': gymName,
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

  Map<String, dynamic> _body(Response res) {
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception(
      (res.data as Map<String, dynamic>?)?['message'] ?? 'Request failed',
    );
  }
}
