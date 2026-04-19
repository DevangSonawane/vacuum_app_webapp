import 'package:dio/dio.dart';

import '../domain/report.dart';

class ReportsRepository {
  ReportsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Report>> fetchReports({String status = ''}) async {
    final response = await _dio.get(
      '/reports',
      queryParameters: {
        'limit': 100,
        if (status.isNotEmpty && status != 'All') 'status': status,
      },
    );
    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map((e) => Report.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Report> fetchById(String id) async {
    final response = await _dio.get('/reports/$id');
    return Report.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<String> create(Map<String, dynamic> payload) async {
    final response = await _dio.post('/reports', data: payload);
    final root = _asMap(response.data);
    final data = _asMap(root['data'] ?? root);
    final id = (data['id'] ?? '').toString();
    return id;
  }

  Future<void> updateStatus(String id, String status) =>
      _dio.patch('/reports/$id/status', data: {'status': status});

  Future<String?> uploadImage(String reportId, String filePath, String filename) async {
    final formData = FormData.fromMap({
      'images': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _dio.post(
      '/upload',
      queryParameters: {'entity_type': 'report', 'entity_id': reportId},
      data: formData,
    );
    final uploaded = _asList(_asMap(response.data)['data']);
    if (uploaded.isEmpty) return null;
    return _asMap(uploaded.first)['file_url']?.toString();
  }

  Future<void> linkImage(String reportId, Map<String, dynamic> data) =>
      _dio.post('/reports/$reportId/images', data: data);

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

