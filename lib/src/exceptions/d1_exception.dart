class D1Exception implements Exception {
  final String message;
  final String? details;
  final int? statusCode;
  final Object? cause;

  const D1Exception(
      this.message, [
        this.details,
        this.statusCode,
        this.cause,
      ]);

  factory D1Exception.network(String message, [Object? cause]) {
    return D1Exception(message, null, null, cause);
  }

  factory D1Exception.api(String message, int statusCode, [String? details]) {
    return D1Exception(message, details, statusCode);
  }

  factory D1Exception.config(String message) {
    return D1Exception(message);
  }

  factory D1Exception.sql(String message, [String? details]) {
    return D1Exception(message, details);
  }

  @override
  String toString() {
    final buffer = StringBuffer('D1Exception: $message');

    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }

    if (details != null) {
      buffer.write('\nDetails: $details');
    }

    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is D1Exception &&
        other.message == message &&
        other.details == details &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode => Object.hash(message, details, statusCode);
}
