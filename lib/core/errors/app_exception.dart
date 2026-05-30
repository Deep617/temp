import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────
//  AppError — single error model used across all BLoCs
// ─────────────────────────────────────────────────────────
class AppException extends Equatable {
  final String message;
  final int? statusCode;
  final String type; // network | auth | validation | server | unknown

  const AppException({
    required this.message,
    this.statusCode,
    this.type = 'unknown',
  });

  static AppException handle(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return AppException(
            message:
                'Connection timed out. Check your '
                'internet.',
            type: 'network',
          );
        case DioExceptionType.connectionError:
          return const AppException(
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
            return AppException(
              message: message,
              statusCode: 401,
              type: 'auth',
            );
          }
          if (code == 403) {
            return AppException(
              message: 'Access denied.',
              statusCode: 403,
              type: 'auth',
            );
          }
          if (code == 422 || code == 400) {
            return AppException(
              message: message,
              statusCode: code,
              type: 'validation',
            );
          }
          return AppException(
            message: message,
            statusCode: code,
            type: 'server',
          );
        default:
          return AppException(
            message: e.message ?? 'Network error.',
            type: 'network',
          );
      }
    }
    if (e is FormatException) {
      return AppException(message: "Data parsing error");
    }

    return AppException(message: e.toString());
  }

  bool get isAuth => type == 'auth';

  bool get isNetwork => type == 'network';

  bool get isValidation => type == 'validation';

  @override
  List<Object?> get props => [message, statusCode, type];

  @override
  String toString() => 'AppError($type): $message';
}
