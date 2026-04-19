import 'package:dio/dio.dart';

import '../domain/client.dart';

class ClientsRepository {
  ClientsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Client>> fetchClients({String search = '', String type = ''}) async {
    final response = await _dio.get(
      '/clients',
      queryParameters: {
        'limit': 50,
        if (search.isNotEmpty) 'search': search,
        if (type.isNotEmpty && type != 'All') 'type': type,
      },
    );

    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map((e) => Client.fromJson(_asMap(e)))
        .toList();
  }

  Future<Client> fetchById(int id) async {
    final response = await _dio.get('/clients/$id');
    final root = _asMap(response.data);
    final data = _asMap(root['data'] ?? root);
    return Client.fromJson(data);
  }

  Future<void> create(Map<String, dynamic> payload) => _dio.post('/clients', data: payload);
  Future<void> update(int id, Map<String, dynamic> payload) => _dio.put('/clients/$id', data: payload);
  Future<void> delete(int id) => _dio.delete('/clients/$id');

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

