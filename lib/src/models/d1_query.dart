import 'package:meta/meta.dart';

@immutable
class D1Query {
  final String sql;
  final List<dynamic>? params;

  const D1Query({
    required this.sql,
    this.params,
  });

  factory D1Query.withParams(String sql, List<dynamic> params) {
    return D1Query(sql: sql, params: params);
  }

  factory D1Query.simple(String sql) {
    return D1Query(sql: sql);
  }

  Map<String, dynamic> toJson() {
    return {
      'sql': sql,
      if (params != null && params!.isNotEmpty) 'params': params,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is D1Query &&
        other.sql == sql &&
        _listEquals(other.params, params);
  }

  @override
  int get hashCode => Object.hash(sql, params);

  @override
  String toString() {
    return 'D1Query(sql: $sql, params: $params)';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
