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

  Future<Response> updateProfile(Map<String, dynamic> data  ) async {
    final response = await client.put(
      ApiEndpoints.updateProfile,
      data: data,
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


  // Submit photo/selfie verification
  Future<Response> submitVerification({
    required String type,      // 'id' or 'selfie'
      String? filePath,
    String? selfieFilePath,
  }) async {
    String? docUrl;
    if (filePath != null) {
      // Step 1: Upload document image
      final docForm = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath!, filename: 'doc.jpg'),
        'folder': 'verifications',
      });
      final uploadRes = await client.post(
          ApiEndpoints.uploadAvatar, data: docForm);
        docUrl = uploadRes.data['data']['url'] as String;
    }
    // Step 2: Upload selfie if provided
    String? selfieUrl;
    if (selfieFilePath != null) {
      final selfieForm = FormData.fromMap({
        'file':   await MultipartFile.fromFile(selfieFilePath, filename: 'selfie.jpg'),
        'folder': 'verifications',
      });
      final selfieRes = await client.post(ApiEndpoints.uploadAvatar, data: selfieForm);
      selfieUrl = selfieRes.data['data']['url'] as String;
    }

    // Step 3: Submit to verification queue
    final response = await client.post(
      '/verification/submit',
      data: {
        'type':      type,
        if (docUrl != null) 'docUrl':    docUrl,
        if (selfieUrl != null) 'selfieUrl': selfieUrl,
      },
    );
    return response;
  }

  // Get my verification status
  Future<Response> getVerificationStatus() async {
    final response = await client.get('/verification/status');
    return response;
  }
}
