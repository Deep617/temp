import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/dio_client.dart';
import '../request_ml/login_request.dart';
import '../request_ml/register_request.dart';
import '../response_ml/register_response.dart';

class AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSource(this.client);

  Future<Response> login(LoginRequest request) async {
    final response = await client.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return response;
  }

  Future<Response> register(RegisterRequest registerRequest) async {
    final response = await client.post(
      ApiEndpoints.register,
      data: registerRequest.toJson(),
    );

    return response;
  }

  Future<Response> refreshToken(String refreshToken) async {
    final response = await client.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    return response;
  }

  Future<Response> logout() async {
    final response = await client.post('/auth/logout');

    return response;
  }

  Future<void> markWalkthroughSeen() async {
    await client.patch('/users/me', queryParameters: {'walkthroughSeen': true});
  }


  // ── Forgot Password ───────────────────────────────────────
  Future<void> sendForgotPasswordOtp(String email) async {
    await client.post('/auth/forgot-password', data: { 'email': email });
  }

  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    await client.post('/auth/verify-otp', data: { 'email': email, 'otp': otp });
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await client.post('/auth/reset-password', data: {
      'email':       email,
      'otp':         otp,
      'newPassword': newPassword,
    });
  }


  // ── Influencer API ────────────────────────────────────────

  Future<Map<String, dynamic>> applyAsInfluencer({
    required String instagramHandle,
    required int    claimedFollowers,
  }) async {
    final res = await client.post('/influencer/apply', data: {
      'instagramHandle':  instagramHandle,
      'claimedFollowers': claimedFollowers,
    });
    return _data(res);
  }

  Future<void> markInfluencerCodeAdded() async {
    await client.post('/influencer/code-added');
  }

  Future<InfluencerApplicationStatus> getInfluencerStatus() async {
    final res = await client.get('/influencer/status');
    return InfluencerApplicationStatus.fromJson(_data(res));
  }

  Future<List<InfluencerProfile>> discoverInfluencers({
    String? activity,
    String? city,
    int page = 1,
  }) async {
    final res = await client.get('/influencer/discover', queryParameters: {
      if (activity != null) 'activity': activity,
      if (city     != null) 'city':     city,
      'page': page,
    });
    final data = _data(res);
    return (data['influencers'] as List<dynamic>)
        .map((e) => InfluencerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InfluencerProfile> getInfluencerProfile(String id) async {
    final res = await client.get('/influencer/$id');
    return InfluencerProfile.fromJson(_data(res));
  }

// ── Match Requests API ────────────────────────────────────

  Future<List<MatchRequest>> getMatchRequests() async {
    final res  = await client.get('/match/requests');
    final data = _data(res);
    return (data['requests'] as List<dynamic>)
        .map((e) => MatchRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> acceptMatchRequest(String swipeId) async {
    final res = await client.post('/match/requests/$swipeId/accept');
    return _data(res);
  }

  Future<void> declineMatchRequest(String swipeId) async {
    await client.post('/match/requests/$swipeId/decline');
  }

  Future<Map<String, dynamic>> swipeUser({
    required String targetId,
    String action = 'like',
  }) async {
    final res = await client.post('/match/swipe', data: {
      'targetId': targetId,
      'action':   action,
    });
    return _data(res);
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
