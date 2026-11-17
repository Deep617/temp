import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';
import '../models/gym_models.dart';

class GymMapRemoteDatasource {
  GymMapRemoteDatasource(this._dio);
  final DioClient _dio;

  /// GET /gyms/nearby — Google Places gyms + buddies checked in there
  Future<List<Gym>> nearby({
    required double lat,
    required double lng,
    int radiusM = 3000,
    String? query,
  }) async {
    final res = await _dio.get('/gyms/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radiusM,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = _data(res) as Map<String, dynamic>? ?? {};
    return (data['gyms'] as List<dynamic>? ?? [])
        .map((e) => Gym.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /gyms/buddies — my buddies' active check-ins
  Future<List<BuddyCheckin>> buddies() async {
    final res = await _dio.get('/gyms/buddies');
    final data = _data(res) as Map<String, dynamic>? ?? {};
    return (data['buddies'] as List<dynamic>? ?? [])
        .map((e) => BuddyCheckin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BuddyCheckin?> myCheckin() async {
    final res = await _dio.get('/gyms/checkin/me');
    final c = (_data(res) as Map<String, dynamic>?)?['checkin'];
    return c is Map<String, dynamic> ? BuddyCheckin.fromJson(c) : null;
  }

  /// [myLat]/[myLng] = where I am now — the server only allows a check-in
  /// when I'm actually at the gym (buddies get notified).
  Future<BuddyCheckin> checkIn(Gym gym, {required double myLat, required double myLng}) async {
    final res = await _dio.post('/gyms/checkin', data: {
      'placeId': gym.placeId,
      'gymName': gym.name,
      'lat': gym.lat,
      'lng': gym.lng,
      'myLat': myLat,
      'myLng': myLng,
      if (gym.address != null) 'address': gym.address,
    });
    final c = (_data(res) as Map<String, dynamic>)['checkin'] as Map<String, dynamic>;
    return BuddyCheckin.fromJson(c);
  }

  Future<void> checkOut() async {
    await _dio.delete('/gyms/checkin');
  }

  /// GET /gyms/map — Buddy Map (buddies at gyms / ~3 km areas) + my Ghost Mode
  Future<BuddyMapData> buddyMap() async {
    final res = await _dio.get('/gyms/map');
    return BuddyMapData.fromJson(_data(res) as Map<String, dynamic>? ?? {});
  }

  /// PUT /users/me { ghostMode: off | 3h | 24h | on }
  Future<void> setGhostMode(String mode) async {
    final res = await _dio.put('/users/me', data: {'ghostMode': mode});
    _data(res);
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
