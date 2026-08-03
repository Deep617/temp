import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';

import '../../di_injection/dependency_injection.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class ApiInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getIt<SecureStorageService>().getAccessToken();
    if (kDebugMode) {
      // print("Token ApiInterceptor onRequest $token");
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print("");
      print("╔════════════════ REQUEST ════════════════");
      print("║ URL: ${options.uri}");
      print("║ HEADERS:");
      options.headers.forEach((key, value) {
        if (kDebugMode) {
          print("║  $key: $value");
        }
      });
      try {
        const encoder = JsonEncoder.withIndent('  ');
        log(
          name: "Api Request Body: ${options.uri}",
          encoder.convert(options.data),
        );
      } catch (e) {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          log('Request Exception:  ${formData.fields}');
          log('Request Exception:  ${formData.files}');
        } else {
          log('Request Exception:  ${options.data}');
        }
      }
      print("╚═════════════════════════════════════════");
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print("");
      print("╔════════════════ RESPONSE ══════════════");
      print("║ URL: ${response.requestOptions.uri}");
      print("║ STATUS CODE: ${response.statusCode}");
      try {
        const encoder = JsonEncoder.withIndent('  ');
        log(
          name: "Api Raw Response: ${response.requestOptions.uri}",
          encoder.convert(response.data),
        );
      } catch (e) {
        log(name: "Response Exception: ", response.data);
      }
      print("╚═════════════════════════════════════════");
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh') &&
        !_refreshing) {
      _refreshing = true;
      try {
        final authRepo = getIt<AuthRepository>();
        final response = await authRepo.refreshToken();
        final newAt = response.data['data']['accessToken'] as String;
        final request = err.requestOptions;
        request.headers['Authorization'] = 'Bearer $newAt';
        final dio = Dio();
        final retryResponse = await dio.fetch(request);
        _refreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        // SecureStorageService service = getIt<SecureStorageService>();
        // await service.clearStorage();
        return handler.next(err);
      }
    }

    if (kDebugMode) {
      print("");
      print("╔════════════════ ERROR ═════════════════");
      print("║ URL: ${err.requestOptions.uri}");
      if (err.response != null) {
        print("║ STATUS CODE: ${err.response?.statusCode}");
      }
      print("║ AppError TYPE: ${err.type}");
      print("║ MESSAGE: ${err.message}");
      print("║ AppError STACKTRACE: ${err.stackTrace}");
      print("║ AppError RESPONSE: ${err.response}");
      if (err.response != null) {
        try {
          const encoder = JsonEncoder.withIndent('  ');
          log(
            name: "Api Error Response: ${err.requestOptions.uri}",
            encoder.convert(err.response?.data),
          );
        } catch (e) {
          log(name: "Error Exception: ", err.response?.data);
        }
      }
      print("╚════════════════════════════════════════");
    }
    return handler.next(err);
  }
}
