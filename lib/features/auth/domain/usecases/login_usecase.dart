import 'package:dio/dio.dart';

import '../../data/models/login_request.dart';
import '../entities/register_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<RegisterResponse> loginPerform({
    required LoginRequest lgnRequest,
  }) {
    return repository.login(lgnRequest);
  }
}
