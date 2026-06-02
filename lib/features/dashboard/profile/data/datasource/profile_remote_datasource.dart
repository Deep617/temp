import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/dio_client.dart';
import '../../../../auth/data/request_ml/upload_profile_request.dart';

class ProfileRemoteDatasource {
  final DioClient client;

  ProfileRemoteDatasource(this.client);

  Future<Response> getMe() async {
    final response = await client.get(ApiEndpoints.authMe);
    return response;
  }

  Future<Response> updateProfile(UploadProfileRequest registerRequest) async {
    final response = await client.put(
      ApiEndpoints.updateProfile,
      queryParameters: registerRequest.toJson(),
    );

    return response;
  }

  Future<Response> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      'folder': 'avatars',
    });
    final response = await client.post(ApiEndpoints.uploadAvatar, data: form);

    return response;
  }
}
