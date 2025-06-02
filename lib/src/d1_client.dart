import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'models/d1_response.dart';
import 'models/d1_query.dart';
import 'models/d1_config.dart';
import 'exceptions/d1_exception.dart';

class D1Client {
  final D1Config _config;
  final http.Client _httpClient;

  D1Client({
    required D1Config config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  Future<D1Response> query(String sql, [List<dynamic>? params]) async {
    return _executeQuery(D1Query(sql: sql, params: params));
  }

  Future<List<D1Response>> batch(List<D1Query> queries) async {
    return _executeBatch(queries);
  }

  Future<D1Response> _executeQuery(D1Query query) async {
    try {
      final url = 'https://api.cloudflare.com/client/v4/accounts/${_config.accountId}/d1/database/${_config.databaseId}/query';

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiToken}',
          ..._config.customHeaders,
        },
        body: jsonEncode({
          'sql': query.sql,
          if (query.params != null && query.params!.isNotEmpty) 'params': query.params,
        }),
      );

      if (response.statusCode != 200) {
        throw D1Exception(
          'REST API error: ${response.statusCode}',
          response.body,
        );
      }

      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        final errors = data['errors'] as List?;
        final errorMessage = errors?.isNotEmpty == true
            ? errors!.first['message']
            : 'Unknown API error';
        throw D1Exception('API Error', errorMessage);
      }

      return D1Response.fromJson(data['result']);
    } catch (e) {
      if (e is D1Exception) rethrow;
      throw D1Exception('Network error', e.toString());
    }
  }

  Future<List<D1Response>> _executeBatch(List<D1Query> queries) async {
    final results = <D1Response>[];

    for (final query in queries) {
      final result = await _executeQuery(query);
      results.add(result);
    }

    return results;
  }

  void dispose() {
    _httpClient.close();
  }
}
