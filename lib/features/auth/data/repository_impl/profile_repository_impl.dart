import 'package:new_arch/core/services/secure_storage_service.dart';
import 'package:new_arch/features/auth/data/datasource/profile_remote_datasource.dart';
import 'package:new_arch/features/auth/domain/entities/register_response.dart';
import 'package:new_arch/features/auth/domain/repositories/profile_repository.dart';

import '../../../../core/api/base_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/upload_profile_request.dart';

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
  Future<RegisterResponse> getMe() async {
    try {
      return await safeApiCall(() async {
        final response = await remote.getMe();
        RegisterResponse registerResponse = RegisterResponse.fromJson(
          response.data['data'],
        );
        return registerResponse;
      });
    } catch (e) {
      throw AppException.handle(e);
    }
  }

  @override
  Future<RegisterResponse> updateProfile(UploadProfileRequest request) async {
    try {
      return await safeApiCall(() async {
        final response = await remote.updateProfile(request);
        RegisterResponse registerResponse = RegisterResponse.fromJson(
          response.data['data'],
        );
        return registerResponse;
      });
    } catch (e) {
      throw AppException.handle(e);
    }
  }

  @override
  Future<String> uploadAvatar(String request) async {
    try {
      return await safeApiCall(() async {
        final response = await remote.uploadAvatar(request);
        String registerResponse = response.data['data']['url'] as String;

        return registerResponse;
      });
    } catch (e) {
      throw AppException.handle(e);
    }
  }
}
