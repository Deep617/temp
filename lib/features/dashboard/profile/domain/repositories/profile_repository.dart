import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';

abstract class ProfileRepository {
  ProfileRepository();

  Future<RegisterResponse> getMe();

  Future<RegisterResponse> updateProfile(UploadProfileRequest request);

  Future<String> uploadAvatar(String request);
}
