import 'package:seshlly/features/dashboard/discover/data/repositories/discover_repository.dart';

import '../../../../auth/data/response_ml/register_response.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<User> updateProfile({required Map<String, dynamic> data}) {
    return repository.updateProfile(data);
  }
}

class UpdateProfileAvatarUseCase {
  final ProfileRepository repository;

  UpdateProfileAvatarUseCase(this.repository);

  Future<String> uploadAvatar(String data) {
    return repository.uploadAvatar(data);
  }
}

class OnloadProfileUseCase {
  final ProfileRepository repository;

  OnloadProfileUseCase(this.repository);

  Future<User> getMe() {
    return repository.getMe();
  }
}

class GetBuddyProfileUseCase {
  final DiscoverRepository repository;

  GetBuddyProfileUseCase(this.repository);

  Future<BuddyProfile> getBuddyProfile(String userId) {
    return repository.getBuddyProfile(userId);
  }
}
