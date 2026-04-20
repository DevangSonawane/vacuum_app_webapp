import 'package:dio/dio.dart';

import '../domain/technician.dart';

class TechniciansRepository {
  TechniciansRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Technician>> fetchTechnicians({String search = ''}) async {
    final response = await _dio.get(
      'technicians',
      queryParameters: {
        'limit': 50,
        if (search.isNotEmpty) 'search': search,
      },
    );

    final root = _asMap(response.data);
    if (root['success'] == true) {
      final list = _asList(root['data']);
      return list
          .whereType<Map>()
          .map((e) => Technician.fromJson(_asMap(e)))
          .toList();
    }

    final list = _asList(root['data']);
    if (list.isNotEmpty) {
      return list
          .whereType<Map>()
          .map((e) => Technician.fromJson(_asMap(e)))
          .toList();
    }

    throw Exception((root['message'] ?? 'Failed to load technicians').toString());
  }

  Future<Technician> fetchById(int id) async {
    final response = await _dio.get('technicians/$id');
    final root = _asMap(response.data);
    final data = root['success'] == true ? _asMap(root['data']) : _asMap(root['data'] ?? root);
    return Technician.fromJson(data);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post('technicians', data: payload);
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _dio.put('technicians/$id', data: payload);
  }

  Future<void> delete(int id) async {
    await _dio.delete('technicians/$id');
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
