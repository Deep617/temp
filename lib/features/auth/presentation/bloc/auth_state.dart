import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/response_ml/register_response.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, onboarding }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  final AuthStatus status;
  final User? user;
  final AppError? error;

  bool get isLoading => status == AuthStatus.loading;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  bool get isOnboarding => status == AuthStatus.onboarding;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    AppError? error,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [status, user, error];
}
