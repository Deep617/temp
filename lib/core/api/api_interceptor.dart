import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:new_arch/core/services/secure_storage_service.dart';

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
      print("Token ApiInterceptor onRequest $token");
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print("");
      print("╔════════════════ REQUEST ════════════════");
      print("║ URL: ${options.uri}");
      print("║ METHOD: ${options.method}");
      print("║ HEADERS:");
      options.headers.forEach((key, value) {
        if (kDebugMode) {
          print("║ $key: $value");
        }
      });
      print("║ BODY:");
      try {
        const encoder = JsonEncoder.withIndent('  ');
        log(
          name: "Api ApiInterceptor Request:=",
          encoder.convert(options.data),
        );
      } catch (e) {
        log(name: "Log Request Exception:=", options.data);
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
      print("║ RESPONSE:");
      try {
        const encoder = JsonEncoder.withIndent('  ');
        log(
          name: "Api ApiInterceptor Response:=",
          encoder.convert(response.data),
        );
      } catch (e) {
        log(name: "Log Response Exception:=", response.data);
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
        // StorageService service = getIt<StorageService>();
        //  await service.clearStorage();
        return handler.next(err);
      }
    }

    if (kDebugMode) {
      print("");
      print("╔════════════════ ERROR ═════════════════");
      print("║ URL: ${err.requestOptions.uri}");
      print("║ MESSAGE: ${err.message}");
      if (err.response != null) {
        print("║ STATUS CODE: ${err.response?.statusCode}");
        try {
          const encoder = JsonEncoder.withIndent('  ');
          log(
            name: "Api ApiInterceptor Error Response:=",
            encoder.convert(err.response?.data),
          );
        } catch (e) {
          log(name: "Log Error Exception:=", err.response?.data);
        }
      }
      print("╚════════════════════════════════════════");
    }
    return handler.next(err);
  }
}
