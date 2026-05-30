import 'package:dio/dio.dart';
import 'package:new_arch/features/auth/data/models/register_request.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/dio_client.dart';
import '../models/login_request.dart';

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
}
