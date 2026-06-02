import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<RegisterResponse> updateProfilePerform({
    required UploadProfileRequest lgnRequest,
  }) {
    return repository.updateProfile(lgnRequest);
  }
}

class OnloadProfileUseCase {
  final ProfileRepository repository;
  OnloadProfileUseCase(this.repository);
  Future<RegisterResponse> getMe() {
    return repository.getMe( );
  }
}
