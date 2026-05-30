class ApiFailure {
  final int? code;
  final String message;
  final dynamic data;

  ApiFailure({
    this.code,
    required this.message,
    this.data,
  });
}