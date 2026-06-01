import 'package:dio/dio.dart';

import '../../data/request_ml/register_request.dart';
import '../../data/response_ml/register_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<RegisterResponse> registerCase({required RegisterRequest
  registerRequest}) {
    return repository.register(registerRequest);
  }
}
