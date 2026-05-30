import 'package:dio/dio.dart';
import 'package:seshlly/features/auth/data/models/register_request.dart';

import '../entities/register_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<RegisterResponse> registerCase({required RegisterRequest
  registerRequest}) {
    return repository.register(registerRequest);
  }
}
