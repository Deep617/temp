import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../response_ml/buddy_profile.dart';
import '../../../../../core/services/offline_cache.dart';

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
    Future<List<dynamic>> load() async {
    final res = await _dio.get(
      '/match/discover',
      queryParameters: {
        if (activity != null) 'activity': activity,
        if (level != null) 'level': level,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        // if (maxDistance != null) 'maxDistance': maxDistance,
        if (maxDistance != null) 'maxDistance': maxDistance.clamp(1.0, 10.0),
        'page': page,
        'limit': 20,
      },
    );
    return _body(res)['data'] as List;
    }

    // First page is cached for offline use (only the unfiltered deck)
    final cacheable = page == 1 && activity == null && level == null;
    final rows = cacheable
        ? await OfflineCache.fetch<List<dynamic>>(
            'discover',
            load,
            toJson: (v) => v,
            fromJson: (j) => j as List<dynamic>,
          )
        : await load();
    return rows
        .map((e) => BuddyProfile.fromJson(Map<String, dynamic>.from(e as Map)))
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

  // POST /match/swipe { targetId, action: 'super_like' }
  // Response: { success, message, data: { matched, matchId? } }
  Future<Map<String, dynamic>> superLike(String targetUserId) async {
    final res = await _dio.post(
      '/match/swipe',
      data: {
        'targetId': targetUserId,
        'action':   'super_like',
      },
    );
    return _body(res);
  }

  // POST /match/boost
  // Response data: { boostExpiresAt, tokensRemaining, durationMinutes }
  Future<Map<String, dynamic>> boost() async {
    final res = await _dio.post('/match/boost');
    return _body(res);
  }

  // GET /match/boost/status
  // Response data: { isActive, boostExpiresAt, remainingMinutes, tokens }
  Future<Map<String, dynamic>> boostStatus() async {
    final res = await _dio.get('/match/boost/status');
    return _body(res);
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
