import 'package:dio/dio.dart';

import '../domain/amc_contract.dart';

class AmcRepository {
  AmcRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AmcContract>> fetchContracts({String status = ''}) async {
    final response = await _dio.get(
      'amc',
      queryParameters: {
        'limit': 100,
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

  Future<AmcContract> fetchById(String id) async {
    final response = await _dio.get('amc/$id');
    return AmcContract.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<void> create(Map<String, dynamic> payload) =>
      _dio.post('amc', data: payload);
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
