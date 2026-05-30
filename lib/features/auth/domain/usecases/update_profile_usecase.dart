import 'package:seshlly/features/auth/data/models/upload_profile_request.dart';
import 'package:seshlly/features/auth/domain/repositories/profile_repository.dart';

import '../entities/register_response.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<RegisterResponse> updateProfilePerform({
    required UploadProfileRequest lgnRequest,
  }) {
    return repository.updateProfile(lgnRequest);
  }
}
