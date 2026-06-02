import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/dio_client.dart';
import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../response_ml/buddy_profile.dart';

class DiscoverRemoteDatasource {
  final DioClient _dio;

  DiscoverRemoteDatasource(this._dio);

  // DISCOVER
  Future<List<BuddyProfile>> getDiscoverProfiles({
    String? activity,
    String? level,
    double? lat,
    double? lng,
    double? maxDistance,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/match/discover',
      queryParameters: {
        if (activity != null) 'activity': activity,
        if (level != null) 'level': level,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (maxDistance != null) 'maxDistance': maxDistance,
        'page': page,
        'limit': 20,
      },
    );
    return (_body(res)['data'] as List)
        .map((e) => BuddyProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> swipeRight(String targetUserId) async {
    final res = await _dio.post(
      '/match/like',
      data: {'targetUserId': targetUserId},
    );
    return _body(res);
  }

  Future<void> swipeLeft(String targetUserId) async {
    await _dio.post('/match/skip', data: {'targetUserId': targetUserId});
  }

  Future<BuddyProfile> getBuddyProfile(String userId) async {
    final res = await _dio.get('/users/$userId/profile');
    return BuddyProfile.fromJson(_body(res)['data'] as Map<String, dynamic>);
  }

  Future<List<BuddyProfile>> getMyBuddies({int page = 1}) async {
    final res = await _dio.get(
      '/match/buddies',
      queryParameters: {'page': page},
    );
    return (_body(res)['data'] as List)
        .map((e) => BuddyProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeBuddy(String buddyId) async {
    await _dio.delete('/match/buddies/$buddyId');
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
