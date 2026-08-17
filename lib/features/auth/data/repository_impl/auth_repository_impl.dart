import 'package:dio/dio.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';

import '../../../../core/api/base_repository.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';
import '../request_ml/login_request.dart';
import '../request_ml/register_request.dart';
import '../response_ml/register_response.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remote;
  final SecureStorageService secureStorageService;

  AuthRepositoryImpl(
    this.secureStorageService,
    this.remote,
    super.connectivity,
  );

  @override
  Future<RegisterResponse> login(LoginRequest request) async {
    return await safeApiCall(() async {
      final response = await remote.login(request);
      RegisterResponse registerResponse = RegisterResponse.fromJson(
        response.data['data'],
      );
      return registerResponse;
    });
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    return await safeApiCall(() async {
      final response = await remote.register(request);
      RegisterResponse registerResponse = RegisterResponse.fromJson(
        response.data['data'],
      );
      return registerResponse;
    });
  }

  @override
  Future<Response> refreshToken() async {
    final refreshToken = await secureStorageService.getRefreshToken();
    if (refreshToken == null) {
      throw Exception("Refresh token missing");
    }
    final response = await remote.refreshToken(refreshToken);
    final newAt = response.data['data']['accessToken'] as String;
    final newRt = response.data['data']['refreshToken'] as String;
    await secureStorageService.saveAccessToken(newAt);
    await secureStorageService.saveRefreshToken(newRt);
    return response;
  }

  @override
  Future<Response> logout() async {
    return await safeApiCall(() async {
      final response = await remote.logout();
      return response;
    });
  }

  @override
  Future<void> markWalkthroughSeen() {
    return remote.markWalkthroughSeen().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // ── Forgot Password ───────────────────────────────────────
  @override
  Future<void> sendForgotPasswordOtp(String email) async {
    return remote.sendForgotPasswordOtp(email).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    return remote.verifyForgotPasswordOtp(email: email, otp: otp).catchError((
      e,
    ) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return remote
        .resetPassword(email: email, otp: otp, newPassword: newPassword)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  @override
  Future<Map<String, dynamic>> applyAsInfluencer({
    required String instagramHandle,
    required int claimedFollowers,
  }) async {
    return remote
        .applyAsInfluencer(
          instagramHandle: instagramHandle,
          claimedFollowers: claimedFollowers,
        )
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  @override
  Future<void> markInfluencerCodeAdded() async {
    return remote.markInfluencerCodeAdded().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<InfluencerApplicationStatus> getInfluencerStatus() async {
    return remote.getInfluencerStatus().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<List<InfluencerProfile>> discoverInfluencers({
    String? activity,
    String? city,
    int page = 1,
  }) async {
    return remote
        .discoverInfluencers(activity: activity, city: city, page: page)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  @override
  Future<InfluencerProfile> getInfluencerProfile(String id) async {
    return remote.getInfluencerProfile(id).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // ── Match Requests API ────────────────────────────────────

  @override
  Future<List<MatchRequest>> getMatchRequests() async {
    return remote.getMatchRequests().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Map<String, dynamic>> acceptMatchRequest(String swipeId) async {
    return remote.acceptMatchRequest(swipeId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> declineMatchRequest(String swipeId) async {
    return remote.declineMatchRequest(swipeId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Map<String, dynamic>> swipeUser({
    required String targetId,
    String action = 'like',
  }) async {
    return remote.swipeUser(targetId: targetId, action: action).catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
