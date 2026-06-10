import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────
//  AppError — single error model used across all BLoCs
// ─────────────────────────────────────────────────────────
class AppError extends Equatable {
  final String message;
  final int? statusCode;
  final String type; // network | auth | validation | server | unknown

  const AppError({
    required this.message,
    this.statusCode,
    this.type = 'unknown',
  });

  static AppError fromException(dynamic e) {
    if (kDebugMode) {
      print("AppError Top Level Exception ${e.toString()}");
      print("TYPE: ${e.type}");
      print("MESSAGE: ${e.message}");
      print("ERROR: ${e.error}");
      print("RESPONSE: ${e.response?.data}");
    }

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return AppError(
            message:
                'Connection timed out. Check your '
                'internet.',
            type: 'network',
          );
        case DioExceptionType.connectionError:
          return const AppError(
            message: 'No internet connection.',
            type: 'network',
          );
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          final body = e.response?.data;
          final message =
              (body is Map ? body['message'] as String? : null) ??
              e.message ??
              'Request failed';
          if (code == 401) {
            return AppError(message: message, statusCode: 401, type: 'auth');
          }
          if (code == 403) {
            return AppError(
              message: 'Access denied.',
              statusCode: 403,
              type: 'auth',
            );
          }
          if (code == 422 || code == 400) {
            return AppError(
              message: message,
              statusCode: code,
              type: 'validation',
            );
          }
          return AppError(message: message, statusCode: code, type: 'server');
        default:
          return AppError(
            message: e.message ?? 'Network error.',
            type: 'network',
          );
      }
    }
    if (e is FormatException) {
      return AppError(message: "Data parsing error");
    }

    return AppError(message: e.toString());
  }

  bool get isAuth => type == 'auth';

  bool get isNetwork => type == 'network';

  bool get isValidation => type == 'validation';

  @override
  List<Object?> get props => [message, statusCode, type];

  @override
  String toString() => 'AppError($type): $message';
}
