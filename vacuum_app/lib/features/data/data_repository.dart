import 'package:dio/dio.dart';

class DataRepository {
  DataRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchVisitSchedule({
    int? month,
    int? year,
    int? day,
    String? technicianId,
    String? status,
    String? category,
  }) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    if (day != null) params['day'] = day;
    if (technicianId != null && technicianId.trim().isNotEmpty) {
      params['technician_id'] = technicianId.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }

    final res = await _dio.get('data/visit-schedule', queryParameters: params);
    final root = _asMap(res.data);
    final list = _asList(root['data']);
    return [
      for (final e in list.whereType<Map>())
        e.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }

  Future<List<Map<String, dynamic>>> fetchReportsData() async {
    final res = await _dio.get('data/reports');
    final root = _asMap(res.data);
    final list = _asList(root['data']);
    return [
      for (final e in list.whereType<Map>())
        e.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }

  Future<Map<String, dynamic>> fetchDashboardUserWise() async {
    final res = await _dio.get('data/dashboard-user-wise');
    final root = _asMap(res.data);
    final data = _asMap(root['data']);
    return data;
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];
