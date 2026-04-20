import 'package:dio/dio.dart';

import '../domain/job.dart';

class JobsRepository {
  JobsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Job>> fetchJobs({String status = ''}) async {
    final response = await _dio.get(
      'jobs',
      queryParameters: {
        'limit': 100,
        if (status.isNotEmpty && status != 'All') 'status': status,
      },
    );

    final data = _asMap(response.data);
    final list = _asList(data['data']);
    return list
        .whereType<Map>()
        .map((e) => Job.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Job> fetchById(String id) async {
    final response = await _dio.get('jobs/$id');
    return Job.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<void> create(Map<String, dynamic> payload) => _dio.post('jobs', data: payload);

  Future<void> advanceStatus(String id, String newStatus) =>
      _dio.patch('jobs/$id/status', data: {'status': newStatus});

  Future<String?> uploadImage(String jobId, String filePath, String filename) async {
    final formData = FormData.fromMap({
      'images': await MultipartFile.fromFile(filePath, filename: filename),
    });

    final response = await _dio.post(
      'upload',
      queryParameters: {'entity_type': 'job', 'entity_id': jobId},
      data: formData,
    );

    final uploaded = _asList(_asMap(response.data)['data']);
    if (uploaded.isEmpty) return null;
    return _asMap(uploaded.first)['file_url']?.toString();
  }

  Future<void> linkImage(String jobId, Map<String, dynamic> imageData) =>
      _dio.post('jobs/$jobId/images', data: imageData);

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
