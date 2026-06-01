
import '../../data/request_ml/upload_profile_request.dart';
import '../../data/response_ml/register_response.dart';
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
