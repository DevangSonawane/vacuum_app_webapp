import 'package:dio/dio.dart';

import '../domain/job.dart';

class JobsRepository {
  JobsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<TechnicianAvailabilityResponse> checkTechnicianAvailability({
    required List<int> technicianIds,
    required String date,
  }) async {
    final response = await _dio.get(
      'jobs/technician-availability',
      queryParameters: {
        'technician_ids': technicianIds.join(','),
        'date': date,
      },
    );

    final root = _asMap(response.data);
    final data = root['data'] is Map ? _asMap(root['data']) : root;
    return TechnicianAvailabilityResponse.fromJson(data);
  }

  Future<List<Job>> fetchJobs({String status = '', int? userId}) async {
    final path = userId != null ? 'jobs/by-user/$userId' : 'jobs';
    final response = await _dio.get(
      path,
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

  Future<void> create(Map<String, dynamic> payload) =>
      _dio.post('jobs', data: payload);

  Future<void> update(String id, Map<String, dynamic> payload) =>
      _dio.put('jobs/$id', data: payload);

  Future<void> delete(String id) => _dio.delete('jobs/$id');

  Future<void> advanceStatus(String id, String newStatus) =>
      _dio.patch('jobs/$id/status', data: {'status': newStatus});

  Future<void> cancel(String id, {String? reason}) async {
    final payload = <String, dynamic>{'status': 'Cancelled'};
    if (reason != null && reason.trim().isNotEmpty) {
      payload['cancel_reason'] = reason.trim();
    }
    await _dio.patch('jobs/$id/status', data: payload);
  }

  Future<String?> uploadImage(
    String jobId,
    String filePath,
    String filename,
  ) async {
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

  Future<void> deleteImage(String jobId, int imageId) =>
      _dio.delete('jobs/$jobId/images/$imageId');

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

class TechnicianAvailabilityResponse {
  const TechnicianAvailabilityResponse({
    required this.date,
    required this.technicians,
  });

  final String date;
  final List<TechnicianAvailability> technicians;

  bool get hasConflicts => technicians.any((tech) => !tech.isAvailable);

  static TechnicianAvailabilityResponse fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    List<dynamic> l(Object? v) => v is List ? v : const [];

    return TechnicianAvailabilityResponse(
      date: s(json['date']),
      technicians: l(json['technicians'])
          .whereType<Map>()
          .map(
            (e) => TechnicianAvailability.fromJson(
              e.map((k, val) => MapEntry(k.toString(), val)),
            ),
          )
          .toList(),
    );
  }
}

class TechnicianAvailability {
  const TechnicianAvailability({
    required this.technicianId,
    required this.technicianName,
    required this.isAvailable,
    required this.conflictingJobs,
  });

  final int technicianId;
  final String technicianName;
  final bool isAvailable;
  final List<ConflictingJob> conflictingJobs;

  static TechnicianAvailability fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    bool b(Object? v) => v is bool ? v : s(v).toLowerCase() == 'true';
    List<dynamic> l(Object? v) => v is List ? v : const [];

    return TechnicianAvailability(
      technicianId: int.tryParse(s(json['technician_id'])) ?? 0,
      technicianName: s(json['technician_name']),
      isAvailable: b(json['is_available']),
      conflictingJobs: l(json['conflicting_jobs'])
          .whereType<Map>()
          .map(
            (e) => ConflictingJob.fromJson(
              e.map((k, val) => MapEntry(k.toString(), val)),
            ),
          )
          .toList(),
    );
  }
}

class ConflictingJob {
  const ConflictingJob({
    required this.jobId,
    required this.title,
    required this.status,
    required this.category,
    required this.clientName,
    required this.scheduledDate,
    required this.startDate,
    required this.endDate,
  });

  final String jobId;
  final String title;
  final String status;
  final String category;
  final String clientName;
  final String? scheduledDate;
  final String? startDate;
  final String? endDate;

  static ConflictingJob fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    String? n(Object? v) {
      final text = s(v).trim();
      return text.isEmpty ? null : text;
    }

    return ConflictingJob(
      jobId: s(json['job_id']),
      title: s(json['title']),
      status: s(json['status']),
      category: s(json['category']),
      clientName: s(json['client_name']),
      scheduledDate: n(json['scheduled_date']),
      startDate: n(json['start_date']),
      endDate: n(json['end_date']),
    );
  }
}
