import 'package:dio/dio.dart';

class DataRepository {
  DataRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchVisitSchedule() async {
    final res = await _dio.get('data/visit-schedule');
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

