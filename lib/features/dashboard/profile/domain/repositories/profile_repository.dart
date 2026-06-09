import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';

abstract class ProfileRepository {
  ProfileRepository();

  Future<User> getMe();

  Future<User> updateProfile(Map<String, dynamic> data  );

  Future<String> uploadAvatar(String request);
}
