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

  Future<UserModel?> getCurrentUserModel() async {
    try {
      final token = await _secureStorageService.getAccessToken();
      if (token == null) return null;
      UserModel userModel = await _profileRepository.getMe();
      return userModel;
    } on AppError catch (e) {
      // Only a rejected login ends the session. No internet / server down
      // must NOT log the user out (it used to wipe the tokens on any error).
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _secureStorageService.clearStorage();
      }
      rethrow;
    } catch (e) {
      final err = AppError.fromException(e);
      if (err.statusCode == 401 || err.statusCode == 403) {
        await _secureStorageService.clearStorage();
      }
      throw err;
    }
  }
}
