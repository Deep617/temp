import 'package:dio/dio.dart';
import 'package:seshlly/core/api/api_endpoints.dart';

import '../../../../core/api/dio_client.dart';
import '../response_ml/app_notification.dart';

class NotificationRemoteDataSource {
  final DioClient _dio;

  NotificationRemoteDataSource(this._dio);

  Future<List<AppNotification>> getNotifications({int page = 1}) async {
    final res = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page},
    );
    return (_body(res)['data'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('${ApiEndpoints.notifications}/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.patch(ApiEndpoints.notificationsReadAll);
  }

  Map<String, dynamic> _body(Response res) {
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception(
      (res.data as Map<String, dynamic>?)?['message'] ?? 'Request failed',
    );
  }
}
