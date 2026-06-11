import 'package:equatable/equatable.dart';

import '../../data/request_ml/register_request.dart';
import '../../data/response_ml/register_response.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final RegisterRequest registerRequest;

  const AuthRegisterRequested({required this.registerRequest});
}

class LogoutSubmitted extends AuthEvent {
  const LogoutSubmitted();
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class AuthUserUpdated extends AuthEvent {
  const AuthUserUpdated({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

class UserTokeExpire extends AuthEvent {
  const UserTokeExpire();
}
