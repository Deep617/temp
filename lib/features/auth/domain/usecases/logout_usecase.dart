import 'package:dio/dio.dart';

import '../../data/request_ml/login_request.dart';
import '../../data/response_ml/register_response.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Response> logoutPerform() {
    return repository.logout();
  }
}
