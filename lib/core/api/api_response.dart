import '../errors/failure.dart';

sealed class ApiState<T, E> {}

class ApiInitial<T, E> extends ApiState<T, E> {}

class ApiLoading<T, E> extends ApiState<T, E> {
  final E event;

  ApiLoading(this.event);
}

class ApiSuccess<T, E> extends ApiState<T, E> {
  final T sccsData;
  final E event;

  ApiSuccess(this.sccsData, this.event);
}

class ApiError<T, E> extends ApiState<T, E> {
  final ApiFailure failureData;
  final E event;

  ApiError(this.failureData, this.event);
}
