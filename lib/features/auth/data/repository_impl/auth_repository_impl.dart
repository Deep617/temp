import 'package:dio/dio.dart';
import 'package:new_arch/core/services/secure_storage_service.dart';
import 'package:new_arch/features/auth/data/models/register_request.dart';
import 'package:new_arch/features/auth/domain/entities/register_response.dart';

import '../../../../core/api/base_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';
import '../models/login_request.dart';

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
    try {
      return await safeApiCall(() async {
        final response = await remote.login(request);
        RegisterResponse registerResponse = RegisterResponse.fromJson(
          response.data['data'],
        );
        return registerResponse;
      });
    } catch (e) {
      throw AppException.handle(e);
    }
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      return await safeApiCall(() async {
        final response = await remote.register(request);
        RegisterResponse registerResponse = RegisterResponse.fromJson(
          response.data['data'],
        );
        return registerResponse;
      });
    } catch (e) {
      throw AppException.handle(e);
    }
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
}
