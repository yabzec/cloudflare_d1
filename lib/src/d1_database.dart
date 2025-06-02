import 'dart:async';

import 'd1_client.dart';
import 'models/d1_query.dart';
import 'models/d1_response.dart';

class D1Database {
  final D1Client _client;

  D1Database(this._client);

  Future<D1Response> execute(String sql, [List<dynamic>? params]) {
    return _client.query(sql, params);
  }

  Future<D1Response> insert(
      String table,
      Map<String, dynamic> data,
      ) async {
    final columns = data.keys.toList();
    final placeholders = List.generate(columns.length, (i) => '?').join(', ');
    final sql = 'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)';

    return _client.query(sql, data.values.toList());
  }

  Future<List<Map<String, dynamic>>> select(
      String table, {
        List<String>? columns,
        String? where,
        List<dynamic>? whereParams,
        String? orderBy,
        int? limit,
        int? offset,
      }) async {
    final columnsStr = columns?.join(', ') ?? '*';
    final sql = StringBuffer('SELECT $columnsStr FROM $table');

    final params = <dynamic>[];

    if (where != null) {
      sql.write(' WHERE $where');
      if (whereParams != null) {
        params.addAll(whereParams);
      }
    }

    if (orderBy != null) {
      sql.write(' ORDER BY $orderBy');
    }

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    if (offset != null) {
      sql.write(' OFFSET $offset');
    }

    final response = await _client.query(sql.toString(), params.isNotEmpty ? params : null);
    return response.allResults;
  }

  Future<D1Response> update(
      String table,
      Map<String, dynamic> data, {
        required String where,
        List<dynamic>? whereParams,
      }) async {
    final setClauses = data.keys.map((key) => '$key = ?').join(', ');
    final sql = 'UPDATE $table SET $setClauses WHERE $where';

    final params = [...data.values];
    if (whereParams != null) {
      params.addAll(whereParams);
    }

    return _client.query(sql, params);
  }

  Future<D1Response> delete(
      String table, {
        required String where,
        List<dynamic>? whereParams,
      }) {
    final sql = 'DELETE FROM $table WHERE $where';
    return _client.query(sql, whereParams);
  }

  Future<int> count(
      String table, {
        String? where,
        List<dynamic>? whereParams,
      }) async {
    final sql = StringBuffer('SELECT COUNT(*) as count FROM $table');

    if (where != null) {
      sql.write(' WHERE $where');
    }

    final response = await _client.query(sql.toString(), whereParams);
    final firstResult = response.firstResult;

    if (firstResult != null && firstResult.containsKey('count')) {
      return firstResult['count'] as int;
    }

    return 0;
  }

  Future<bool> tableExists(String tableName) async {
    const sql = '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name=?
    ''';

    final response = await _client.query(sql, [tableName]);
    return response.hasResults;
  }

  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    final sql = 'PRAGMA table_info($tableName)';
    final response = await _client.query(sql);
    return response.allResults;
  }

  Future<D1Response> createTable(
      String tableName,
      Map<String, String> columns, {
        String? primaryKey,
        List<String>? uniqueColumns,
        Map<String, String>? foreignKeys,
      }) {
    final columnDefinitions = <String>[];

    columns.forEach((name, type) {
      columnDefinitions.add('$name $type');
    });

    if (primaryKey != null) {
      columnDefinitions.add('PRIMARY KEY ($primaryKey)');
    }

    if (uniqueColumns != null && uniqueColumns.isNotEmpty) {
      for (final column in uniqueColumns) {
        columnDefinitions.add('UNIQUE ($column)');
      }
    }

    if (foreignKeys != null) {
      foreignKeys.forEach((column, reference) {
        columnDefinitions.add('FOREIGN KEY ($column) REFERENCES $reference');
      });
    }

    final sql = 'CREATE TABLE $tableName (${columnDefinitions.join(', ')})';
    return _client.query(sql);
  }

  Future<D1Response> dropTable(String tableName, {bool ifExists = true}) {
    final sql = 'DROP TABLE ${ifExists ? 'IF EXISTS ' : ''}$tableName';
    return _client.query(sql);
  }

  Future<List<D1Response>> batch(List<D1Query> queries) {
    return _client.batch(queries);
  }

  Future<Map<String, dynamic>?> findById(
      String table,
      dynamic id, {
        String idColumn = 'id',
        List<String>? columns,
      }) async {
    final results = await select(
      table,
      columns: columns,
      where: '$idColumn = ?',
      whereParams: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> findBy(
      String table,
      String field,
      dynamic value, {
        List<String>? columns,
        String? orderBy,
        int? limit,
      }) {
    return select(
      table,
      columns: columns,
      where: '$field = ?',
      whereParams: [value],
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<bool> exists(
      String table, {
        String? where,
        List<dynamic>? whereParams,
      }) async {
    final count = await this.count(table, where: where, whereParams: whereParams);
    return count > 0;
  }

  Future<Map<String, dynamic>?> first(
      String table, {
        List<String>? columns,
        String? where,
        List<dynamic>? whereParams,
        String? orderBy,
      }) async {
    final results = await select(
      table,
      columns: columns,
      where: where,
      whereParams: whereParams,
      orderBy: orderBy,
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  void dispose() {
    _client.dispose();
  }
}
