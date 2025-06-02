import 'package:meta/meta.dart';

@immutable
class D1Response {
  final bool success;
  final List<Map<String, dynamic>>? results;
  final D1Meta? meta;
  final String? error;
  final int? changes;
  final int? lastRowId;
  final double? duration;

  const D1Response({
    required this.success,
    this.results,
    this.meta,
    this.error,
    this.changes,
    this.lastRowId,
    this.duration,
  });

  factory D1Response.success({
    List<Map<String, dynamic>>? results,
    D1Meta? meta,
    int? changes,
    int? lastRowId,
    double? duration,
  }) {
    return D1Response(
      success: true,
      results: results,
      meta: meta,
      changes: changes,
      lastRowId: lastRowId,
      duration: duration,
    );
  }

  factory D1Response.error(String error) {
    return D1Response(
      success: false,
      error: error,
    );
  }

  factory D1Response.fromJson(Map<String, dynamic> json) {
    return D1Response(
      success: true,
      results: (json['results'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      meta: json['meta'] != null
          ? D1Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      changes: json['changes'] as int?,
      lastRowId: json['last_row_id'] as int?,
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (results != null) 'results': results,
      if (meta != null) 'meta': meta!.toJson(),
      if (error != null) 'error': error,
      if (changes != null) 'changes': changes,
      if (lastRowId != null) 'last_row_id': lastRowId,
      if (duration != null) 'duration': duration,
    };
  }

  Map<String, dynamic>? get firstResult {
    return results?.isNotEmpty == true ? results!.first : null;
  }

  List<Map<String, dynamic>> get allResults {
    return results ?? [];
  }

  bool get hasResults {
    return results?.isNotEmpty == true;
  }

  int get resultCount {
    return results?.length ?? 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is D1Response &&
        other.success == success &&
        other.error == error &&
        other.changes == changes &&
        other.lastRowId == lastRowId;
  }

  @override
  int get hashCode {
    return Object.hash(success, error, changes, lastRowId);
  }

  @override
  String toString() {
    return 'D1Response(success: $success, '
        'resultCount: $resultCount, '
        'changes: $changes, '
        'error: $error)';
  }
}

@immutable
class D1Meta {
  final String? sql;
  final int? rowsRead;
  final int? rowsWritten;
  final int? sizeAfter;
  final List<String>? columns;
  final double? duration;

  const D1Meta({
    this.sql,
    this.rowsRead,
    this.rowsWritten,
    this.sizeAfter,
    this.columns,
    this.duration,
  });

  factory D1Meta.fromJson(Map<String, dynamic> json) {
    return D1Meta(
      sql: json['sql'] as String?,
      rowsRead: json['rows_read'] as int?,
      rowsWritten: json['rows_written'] as int?,
      sizeAfter: json['size_after'] as int?,
      columns: (json['columns'] as List<dynamic>?)?.cast<String>(),
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sql != null) 'sql': sql,
      if (rowsRead != null) 'rows_read': rowsRead,
      if (rowsWritten != null) 'rows_written': rowsWritten,
      if (sizeAfter != null) 'size_after': sizeAfter,
      if (columns != null) 'columns': columns,
      if (duration != null) 'duration': duration,
    };
  }

  @override
  String toString() {
    return 'D1Meta(rowsRead: $rowsRead, rowsWritten: $rowsWritten, duration: $duration)';
  }
}
