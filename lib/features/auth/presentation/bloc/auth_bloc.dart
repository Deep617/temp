import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/auth/domain/usecases/logout_usecase.dart';

import '../../../../core/api/base_state.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/request_ml/login_request.dart';
import '../../data/response_ml/register_response.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final SecureStorageService _sStorageService;

  AuthBloc(
    this._sStorageService,
    this.loginUseCase,
    this.registerUseCase,
    this._logoutUseCase,
  ) : super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegister);
    on<LogoutSubmitted>(_onLogout);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, clearError: true));
    try {
      final RegisterResponse loginResponse = await loginUseCase.loginPerform(
        lgnRequest: LoginRequest(email: event.email, password: event.password),
      );

      _sStorageService.saveAccessToken(loginResponse.accessToken!);
      _sStorageService.saveRefreshToken(loginResponse.refreshToken!);

      emit(state.copyWith(status: ApiStatus.success, user: loginResponse.user));
    } on AppError catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }

  Future<void> _onRegister(
    RegisterSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      final RegisterResponse registerResponse = await registerUseCase
          .registerCase(registerRequest: event.registerRequest);

      _sStorageService.saveAccessToken(registerResponse.accessToken!);
      _sStorageService.saveRefreshToken(registerResponse.refreshToken!);

      emit(
        state.copyWith(status: ApiStatus.success, user: registerResponse.user),
      );
    } on AppError catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }

  Future<void> _onLogout(
    LogoutSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      final Response logoutResponse = await _logoutUseCase.logoutPerform();

      if (logoutResponse.statusCode == 200) {
        await _sStorageService.clearStorage();
      }
      /*      emit(
        state.copyWith(
          status: ApiStatus.success,
          registerResponse: registerResponse,
        ),
      );*/
    } on AppError catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }
}
