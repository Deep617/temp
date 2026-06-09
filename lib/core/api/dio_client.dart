import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'api_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient(this.dio) {
    dio.options = BaseOptions(
      baseUrl: ApiEndpoints.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );

    dio.interceptors.add(ApiInterceptor());
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final stopwatch = Stopwatch()..start();

    Response response = await dio.get(path, queryParameters: queryParameters);
    stopwatch.stop();
    print('POST $path took: ${stopwatch.elapsedMilliseconds} ms');
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }
    throw Exception((response.statusMessage ?? 'Request failed',));
  }

  Future<Response> post(String path, {dynamic data}) async {
    final stopwatch = Stopwatch()..start();
    Response response = await dio.post(path, data: data);
    stopwatch.stop();
    print('POST $path took: ${stopwatch.elapsedMilliseconds} ms');

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }
    throw Exception((response.statusMessage ?? 'Request failed',));
  }

  Future<Response> put(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response = await dio.put(path, queryParameters: queryParameters);
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }
    throw Exception((response.statusMessage ?? 'Request failed',));
  }

  Future<Response> patch(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response = await dio.patch(path, queryParameters: queryParameters);
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }
    throw Exception((response.statusMessage ?? 'Request failed',));
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response = await dio.delete(
      path,
      queryParameters: queryParameters,
    );
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }
    throw Exception((response.statusMessage ?? 'Request failed',));
  }
}
