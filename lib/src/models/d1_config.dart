import 'package:meta/meta.dart';

@immutable
class D1Config {
  final String? accountId;
  final String? databaseId;
  final String? apiToken;
  final Map<String, String> customHeaders;
  final Duration timeout;

  const D1Config({
    this.accountId,
    this.databaseId,
    this.apiToken,
    this.customHeaders = const {},
    this.timeout = const Duration(seconds: 30),
  });

  void validate() {
    if (accountId == null || accountId!.isEmpty) {
      throw ArgumentError('Account ID is required for REST API');
    }
    if (databaseId == null || databaseId!.isEmpty) {
      throw ArgumentError('Database ID is required for REST API');
    }
    if (apiToken == null || apiToken!.isEmpty) {
      throw ArgumentError('API token is required for REST API');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is D1Config &&
        other.accountId == accountId &&
        other.databaseId == databaseId &&
        other.apiToken == apiToken;
  }

  @override
  int get hashCode {
    return Object.hash(
      accountId,
      databaseId,
      apiToken
    );
  }
}
