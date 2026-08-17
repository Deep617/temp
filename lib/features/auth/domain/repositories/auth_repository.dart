import 'package:dio/dio.dart';

import '../../data/request_ml/login_request.dart';
import '../../data/request_ml/register_request.dart';
import '../../data/response_ml/register_response.dart';

abstract class AuthRepository {
  AuthRepository();

  Future<RegisterResponse> login(LoginRequest request);

  Future<RegisterResponse> register(RegisterRequest request);

  Future<Response> logout();

  Future<Response> refreshToken();

  Future<void> markWalkthroughSeen();

  // ── Forgot Password ───────────────────────────────────────
  Future<void> sendForgotPasswordOtp(String email);

  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<Map<String, dynamic>> applyAsInfluencer({
    required String instagramHandle,
    required int claimedFollowers,
  });

  Future<void> markInfluencerCodeAdded();

  Future<InfluencerApplicationStatus> getInfluencerStatus();

  Future<List<InfluencerProfile>> discoverInfluencers({
    String? activity,
    String? city,
    int page = 1,
  });

  Future<InfluencerProfile> getInfluencerProfile(String id);


  // ── Match Requests API ────────────────────────────────────

  Future<List<MatchRequest>> getMatchRequests() ;

  Future<Map<String, dynamic>> acceptMatchRequest(String swipeId) ;

  Future<void> declineMatchRequest(String swipeId) ;

  Future<Map<String, dynamic>> swipeUser({
    required String targetId,
    String action = 'like',
  });

}
