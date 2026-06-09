import 'package:seshlly/core/services/secure_storage_service.dart';
import 'package:seshlly/features/dashboard/profile/domain/repositories/profile_repository.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/request_ml/login_request.dart';
import '../../data/response_ml/register_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  final ProfileRepository _profileRepository;
  final SecureStorageService _secureStorageService;

  LoginUseCase(
    this.repository,
    this._profileRepository,
    this._secureStorageService,
  );

  Future<RegisterResponse> loginPerform({required LoginRequest lgnRequest}) {
    return repository.login(lgnRequest);
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStorageService.getAccessToken();
      if (token == null) return null;
      User user = await _profileRepository.getMe();
      return user;
    } on AppError {
      await   _secureStorageService.clearStorage();
      rethrow;
    } catch (e) {
      await  _secureStorageService.clearStorage();
      throw AppError.fromException(e);
    }
  }
}
