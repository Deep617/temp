import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/auth/domain/usecases/logout_usecase.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/request_ml/login_request.dart';
import '../../data/response_ml/register_response.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final SecureStorageService _sStorageService;
  final StorageService _storageService;

  AuthBloc(
    this._storageService,
    this._sStorageService,
    this.loginUseCase,
    this.registerUseCase,
    this._logoutUseCase,
  ) : super(const AuthState()) {
    if (kDebugMode) {
      print('****** AuthBloc created');
    }
    on<AuthCheckRequested>((event, emit) async {
      if (kDebugMode) {
        print('****** Event received');
      }
      await _onCheckRequested(event, emit);
    });
    on<AuthLoginRequested>(_onLoginSubmitted);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<LogoutSubmitted>(_onLogoutRequested);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (kDebugMode) {
      print("****** onCheckRequested received");
    }

    try {
      final user = await loginUseCase.getCurrentUser();
      if (user == null) {
        if (kDebugMode) {
          print("******* user not");
        }
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      } else {
        if (kDebugMode) {
          print("******* user present");
        }
      }
      bool onboarded = await _storageService.getOnboarding();
      emit(
        state.copyWith(
          status: onboarded ? AuthStatus.authenticated : AuthStatus.onboarding,
          user: user,
        ),
      );
    } on AppError catch (e) {
      if (kDebugMode) {
        print("exception on current user${e.toString()}");
      }
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final RegisterResponse loginResponse = await loginUseCase.loginPerform(
        lgnRequest: LoginRequest(email: event.email, password: event.password),
      );

      _sStorageService.saveAccessToken(loginResponse.accessToken!);
      _sStorageService.saveRefreshToken(loginResponse.refreshToken!);
      bool onboarded = await _storageService.getOnboarding();
      emit(
        state.copyWith(
          status: onboarded ? AuthStatus.authenticated : AuthStatus.onboarding,
          user: loginResponse.user,
        ),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: e));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final RegisterResponse registerResponse = await registerUseCase
          .registerCase(registerRequest: event.registerRequest);

      _sStorageService.saveAccessToken(registerResponse.accessToken!);
      _sStorageService.saveRefreshToken(registerResponse.refreshToken!);

      emit(
        state.copyWith(
          status: AuthStatus.onboarding,
          user: registerResponse.user,
        ),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: e));
    }
  }

  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    await _storageService.setOnboarding();
    emit(state.copyWith(status: AuthStatus.authenticated));
  }

  Future<void> _onLogoutRequested(
    LogoutSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final Response logoutResponse = await _logoutUseCase.logoutPerform();

    if (logoutResponse.statusCode == 200) {
      await _sStorageService.clearStorage();
      await _storageService.clearStorage();
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    emit(state.copyWith(user: event.user));
  }
}
