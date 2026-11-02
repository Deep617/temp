import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';

import '../../di_injection/dependency_injection.dart';
import 'idempotency.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class ApiInterceptor extends Interceptor {
  // One refresh at a time; every 401 that arrives meanwhile waits for it.
  // (Before: the flag was never reset after a failed refresh, so after the
  // first failure no request could ever refresh again until app restart.)
  static Completer<String?>? _refresh;

  /// Returns the new access token, or null if the session is really over.
  Future<String?> _refreshAccessToken() {
    final running = _refresh;
    if (running != null) return running.future;
    final c = Completer<String?>();
    _refresh = c;
    () async {
      try {
        final response = await getIt<AuthRepository>().refreshToken();
        c.complete(response.data['data']['accessToken'] as String);
      } catch (e) {
        final code = e is DioException ? e.response?.statusCode : null;
        final noToken = e.toString().contains('Refresh token missing');
        if (code == 401 || code == 403 || noToken) {
          // Refresh token rejected → sign out cleanly
          getIt<AuthBloc>().add(const UserTokeExpire());
        }
        c.complete(null);
      } finally {
        _refresh = null;
      }
    }();
    return c.future;
  }

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
    // One key per user action; kept when this same request is retried
    IdempotencyPolicy.attach(options);
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
    // Bad network / server busy → re-send the SAME keyed request (server
    // runs it once). The user just sees it work.
    final attempt = (err.requestOptions.extra['idemRetry'] as int?) ?? 0;
    if (IdempotencyPolicy.shouldRetry(err, attempt)) {
      await Future<void>.delayed(IdempotencyPolicy.backoff(attempt));
      final request = err.requestOptions..extra['idemRetry'] = attempt + 1;
      try {
        final token = await getIt<SecureStorageService>().getAccessToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        return handler.resolve(await Dio().fetch(request));
      } on DioException catch (e) {
        if (IdempotencyPolicy.shouldRetry(e, attempt + 1)) {
          return onError(e, handler);
        }
        err = e;
      }
    }
    final path = err.requestOptions.path;
    final isAuthCall = path.contains('/auth/refresh') ||
        path.contains('/auth/login') || path.contains('/auth/register');
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (err.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
      final newAt = await _refreshAccessToken();
      if (newAt != null) {
        try {
          final request = err.requestOptions;
          request.headers['Authorization'] = 'Bearer $newAt';
          request.extra['retried'] = true;
          final retryResponse = await Dio().fetch(request);
          return handler.resolve(retryResponse);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      return handler.next(err);
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
