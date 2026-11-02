import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/auth/domain/usecases/logout_usecase.dart';
import 'package:seshlly/features/auth/domain/usecases/onboarding_competed.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/request_ml/login_request.dart';
import '../../data/response_ml/register_response.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:seshlly/core/services/growth_service.dart';
import 'package:seshlly/core/services/offline_cache.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final OnboardingCompeted _onboardingCompeted;
  final SecureStorageService _sStorageService;
  final StorageService _storageService;

  AuthBloc(
    this._storageService,
    this._sStorageService,
    this.loginUseCase,
    this._onboardingCompeted,
    this.registerUseCase,
    this._logoutUseCase,
  ) : super(const AuthState()) {
    if (kDebugMode) {
      print('****** AuthBloc created');
    }
    on<AuthCheckRequested>((event, emit) async {
      if (kDebugMode) {
        print('****** AuthCheckEvent received');
      }
      await _onCheckRequested(event, emit);
    });
    on<AuthLoginRequested>(_onLoginSubmitted);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthLoggedOut>(_onLogoutRequested);
    on<AuthUserUpdated>(_onUserUpdated);
    on<UserTokeExpire>(_onUserTokenNot);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (kDebugMode) {
      print("****** onCheckRequested received");
    }

    try {
      // Flaky network at app start → retry a few times before giving up
      UserModel? user;
      for (var attempt = 0;; attempt++) {
        try {
          user = await loginUseCase.getCurrentUserModel();
          break;
        } on AppError catch (e) {
          if (e.isNetwork && attempt < 2) {
            await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }
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
      // bool onboarded = await _storageService.getOnboarding();
      bool onboarded = user.walkthroughSeen;

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
      // Never leave the user on the splash screen forever. Tokens are kept
      // for network errors, so signing in again is quick once online.
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: e));
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
      // bool onboarded = await _storageService.getOnboarding();
      bool onboarded = loginResponse.user!.walkthroughSeen;
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
      GrowthService.instance.logFirst(GrowthService.signUp);

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
    try {
      await _onboardingCompeted.markWalkthroughSeen();
      await _storageService.setOnboarding();
      // Router checks user.walkthroughSeen — without updating it, new users
      // were sent straight back to onboarding after tapping Finish.
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: state.user?.copyWith(walkthroughSeen: true),
        clearError: true,
      ));
    } on AppError catch (e) {
      emit(state.copyWith(error: e));
    } catch (e) {
      emit(state.copyWith(error: AppError.fromException(e)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    // Always sign out locally, even if the server call fails (offline, 401)
    try {
      final refresh = await _sStorageService.getRefreshToken();
      await _logoutUseCase.logoutPerform(refreshToken: refresh);
    } catch (_) {/* server may be unreachable — still sign out here */}
    await _sStorageService.clearStorage();
    await _storageService.clearStorage();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    emit(state.copyWith(user: event.user));
  }

  Future<void> _onUserTokenNot(
    UserTokeExpire event,
    Emitter<AuthState> emit,
  ) async {
    await _sStorageService.clearStorage();
    await OfflineCache.clear(); // next account must not see this one's data
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}
