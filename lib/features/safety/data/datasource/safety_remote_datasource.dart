import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';

/// Blocked user row (GET /safety/blocked)
class BlockedUser {
  const BlockedUser({required this.id, required this.name, this.avatarUrl});
  final String id;
  final String name;
  final String? avatarUrl;

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
      );
}

class SafetyRemoteDatasource {
  SafetyRemoteDatasource(this._dio);
  final DioClient _dio;

  Future<void> block(String userId) async {
    await _dio.post('/safety/block', data: {'userId': userId});
  }

  Future<void> unblock(String userId) async {
    await _dio.delete('/safety/block/$userId');
  }

  Future<List<BlockedUser>> getBlocked() async {
    final res = await _dio.get('/safety/blocked');
    final data = _data(res) as Map<String, dynamic>? ?? {};
    return (data['users'] as List<dynamic>? ?? [])
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// reason: harassment | fake_profile | inappropriate | spam | safety | underage | other
  Future<void> report({
    required String userId,
    required String reason,
    String? details,
    String? context,
    bool alsoBlock = true,
  }) async {
    await _dio.post('/safety/report', data: {
      'userId': userId,
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
      if (context != null) 'context': context,
      'block': alsoBlock,
    });
  }

  dynamic _data(Response res) {
    final body = res.data;
    if (body is Map && body['success'] == true) return body['data'];
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      message: (body is Map ? body['message'] as String? : null) ?? 'Unexpected response',
    );
  }
}
