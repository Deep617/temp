import 'package:equatable/equatable.dart';

import '../../data/request_ml/register_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  RegisterRequest registerRequest;

  RegisterSubmitted({required this.registerRequest});
}

class LogoutSubmitted extends AuthEvent {
  const LogoutSubmitted();
}
