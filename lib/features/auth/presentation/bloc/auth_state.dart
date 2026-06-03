import '../../../../core/api/base_state.dart';
import '../../../../core/errors/failure.dart';
import '../../data/response_ml/register_response.dart';

class LoginState extends BaseState {
  final User? user;

  const LoginState({super.status, super.error, this.user});

  LoginState copyWith({
    ApiStatus? status,
    ApiFailure? error,
    User? user,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
      user: clearResponse ? null : user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [...super.props, user];
}
