import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';

abstract class ProfileRepository {
  ProfileRepository();

  Future<UserModel> getMe();

  Future<UserModel> updateProfile(Map<String, dynamic> data  );

  Future<String> uploadAvatar(String request);
}
