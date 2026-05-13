class UpdateException implements Exception {
  const UpdateException({
    required this.message,
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'UpdateException(code: $code, message: $message)';
}
