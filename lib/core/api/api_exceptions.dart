/// Domain exception hierarchy.
/// Every error the UI handles is one of these — no raw DioException leaks out.
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);

  @override
  String toString() => message;
}

/// HTTP 4xx / 5xx with server message.
class ApiException extends DomainException {
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required String message,
    this.statusCode,
    this.errors,
  }) : super(message);

  bool get isValidation => statusCode == 422;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimit => statusCode == 429;
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// Returns the first validation message for a field, or null.
  String? fieldError(String field) {
    final list = errors?[field];
    if (list is List && list.isNotEmpty) return list.first.toString();
    return null;
  }
}

/// No internet / connection timeout.
class NetworkException extends DomainException {
  const NetworkException([String message = 'No internet connection.'])
      : super(message);
}

/// Local parsing error.
class ParseException extends DomainException {
  const ParseException([String message = 'Failed to parse response.'])
      : super(message);
}

/// Insufficient wallet balance.
class InsufficientBalanceException extends DomainException {
  final double required;
  final double available;
  final String currency;

  const InsufficientBalanceException({
    required this.required,
    required this.available,
    required this.currency,
  }) : super('Insufficient $currency balance.');
}

/// Helper to extract ApiException from a Dio error chain.
ApiException? extractApiException(Object error) {
  if (error is ApiException) return error;
  return null;
}
