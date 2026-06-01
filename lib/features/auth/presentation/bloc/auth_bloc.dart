import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/auth/domain/usecases/logout_usecase.dart';

import '../../../../core/api/base_state.dart';
import '../../../../core/errors/app_exception.dart';
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

      if (kDebugMode) {
        print("Token on login: ${(loginResponse.accessToken)}");
      }
      _sStorageService.saveAccessToken(loginResponse.accessToken!);
      _sStorageService.saveAccessToken(loginResponse.refreshToken!);
      String? tokienafterSave = await _sStorageService.getAccessToken();
      print("Token on login: ${tokienafterSave}");

      emit(
        state.copyWith(status: ApiStatus.success, loginResponse: loginResponse),
      );
    } on AppException catch (e) {
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

      if (kDebugMode) {
        print("Token on register: ${(registerResponse.accessToken)}");
      }
      _sStorageService.saveAccessToken(registerResponse.accessToken!);
      _sStorageService.saveAccessToken(registerResponse.refreshToken!);
      String? tokienafterSave = await _sStorageService.getAccessToken();
      print("Token on register: ${tokienafterSave}");
      emit(
        state.copyWith(
          status: ApiStatus.success,
          registerResponse: registerResponse,
        ),
      );
    } on AppException catch (e) {
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

        if(logoutResponse.statusCode == 200){
          await _sStorageService.clearStorage();
        }
/*      emit(
        state.copyWith(
          status: ApiStatus.success,
          registerResponse: registerResponse,
        ),
      );*/
    } on AppException catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }
}
