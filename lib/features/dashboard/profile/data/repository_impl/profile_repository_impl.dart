import '../../../../../core/api/base_repository.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasource/profile_remote_datasource.dart';

class ProfileRepositoryImpl extends BaseRepository
    implements ProfileRepository {
  final ProfileRemoteDatasource remote;
  final SecureStorageService secureStorageService;

  ProfileRepositoryImpl(
    this.secureStorageService,
    this.remote,
    super.connectivity,
  );

  @override
  Future<User> getMe() async {
    return await safeApiCall(() async {
      final response = await remote.getMe();
      User registerResponse = User.fromJson(response.data['data']);
      return registerResponse;
    });
  }

  @override
  Future<RegisterResponse> updateProfile(UploadProfileRequest request) async {
    return await safeApiCall(() async {
      final response = await remote.updateProfile(request);
      RegisterResponse registerResponse = RegisterResponse.fromJson(
        response.data['data'],
      );
      return registerResponse;
    });
  }

  @override
  Future<String> uploadAvatar(String request) async {
    return await safeApiCall(() async {
      final response = await remote.uploadAvatar(request);
      String registerResponse = response.data['data']['url'] as String;

      return registerResponse;
    });
  }
}
