import 'package:dio/dio.dart';

import '../domain/amc_contract.dart';

class AmcRepository {
  AmcRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AmcContract>> fetchContracts({
    String status = '',
    int limit = 100,
  }) async {
    final response = await _dio.get(
      'amc',
      queryParameters: {
        'limit': limit,
        if (status.isNotEmpty && status != 'All') 'status': status,
      },
    );
    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map(
          (e) =>
              AmcContract.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }

  Future<List<AmcContract>> fetchExpiring({int days = 30}) async {
    final response = await _dio.get(
      'amc/expiring',
      queryParameters: {'days': days},
    );
    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map(
          (e) =>
              AmcContract.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }

  Future<AmcContract> fetchById(String id) async {
    final response = await _dio.get('amc/$id');
    return AmcContract.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<AmcContract> create(Map<String, dynamic> payload) async {
    final response = await _dio.post('amc', data: payload);
    final root = _asMap(response.data);
    final data = _asMap(root['data'] ?? root);
    return AmcContract.fromJson(data);
  }

  Future<void> sendEmail(String id, String email) =>
      _dio.post('amc/$id/send-email', data: {'email': email.trim()});

  Future<List<int>> exportExcel({
    String status = '',
    String year = '',
    String clientId = '',
  }) async {
    final response = await _dio.get(
      'amc/export/excel',
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (year.isNotEmpty) 'year': year,
        if (clientId.isNotEmpty) 'client_id': clientId,
      },
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;
    if (data is List<int>) return data;
    if (data is List) {
      return data.map((e) => e is int ? e : int.parse(e.toString())).toList();
    }
    throw Exception('Invalid Excel response from server.');
  }

  Future<void> update(String id, Map<String, dynamic> payload) =>
      _dio.put('amc/$id', data: payload);
  Future<void> delete(String id) => _dio.delete('amc/$id');

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
