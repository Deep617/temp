import 'package:new_arch/features/auth/data/models/upload_profile_request.dart';

import '../../data/models/register_request.dart';
import '../entities/register_response.dart';

abstract class ProfileRepository {
  ProfileRepository();

  Future<RegisterResponse> getMe();

  Future<RegisterResponse> updateProfile(UploadProfileRequest request);

  Future<String> uploadAvatar(String request);
}
