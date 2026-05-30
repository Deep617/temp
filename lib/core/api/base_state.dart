import 'package:equatable/equatable.dart';

import '../errors/failure.dart';

enum ApiStatus {
  initial,
  loading,
  success,
  failure,
}

abstract class BaseState extends Equatable {
  final ApiStatus status;
  final ApiFailure? error;

  const BaseState({
    this.status = ApiStatus.initial,
    this.error,
  });

  bool get isInitial => status == ApiStatus.initial;

  bool get isLoading => status == ApiStatus.loading;

  bool get isSuccess => status == ApiStatus.success;

  bool get isFailure => status == ApiStatus.failure;

  @override
  List<Object?> get props => [
    status,
    error,
  ];
}