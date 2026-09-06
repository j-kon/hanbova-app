class AppFailure {
  final String message;
  final String? code;
  final Object? originalError;

  const AppFailure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}
