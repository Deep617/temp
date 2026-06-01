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
}
