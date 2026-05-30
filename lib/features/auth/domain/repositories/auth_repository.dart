import 'package:dio/dio.dart';
import 'package:new_arch/features/auth/data/models/register_request.dart';

import '../../data/models/login_request.dart';
import '../entities/register_response.dart';

abstract class AuthRepository {
  AuthRepository();

  Future<RegisterResponse> login(LoginRequest request);

  Future<RegisterResponse> register(RegisterRequest request);

  Future<Response> refreshToken();
}
