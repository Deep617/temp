import 'package:new_arch/features/auth/domain/entities/register_response.dart';

import '../../../../core/api/base_state.dart';
import '../../../../core/errors/failure.dart';

class LoginState extends BaseState {
  final RegisterResponse? loginResponse;
  final RegisterResponse? registerResponse;

  const LoginState({
    super.status,
    super.error,
    this.loginResponse,
    this.registerResponse,
  });

  LoginState copyWith({
    ApiStatus? status,
    ApiFailure? error,
    RegisterResponse? loginResponse,
    RegisterResponse? registerResponse,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
      loginResponse: clearResponse ? null : loginResponse ?? this.loginResponse,
      registerResponse: clearResponse
          ? null
          : registerResponse ?? this.registerResponse,
    );
  }

  @override
  List<Object?> get props => [...super.props, loginResponse, registerResponse];
}
