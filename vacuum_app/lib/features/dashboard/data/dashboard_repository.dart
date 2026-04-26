import 'package:dio/dio.dart';

import '../domain/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<DashboardData> fetchDashboard() async {
    final response = await _dio.get('dashboard');
    final root = _asMap(response.data);
    final success = root['success'] == true;
    if (!success) {
      throw Exception(
        (root['message'] ?? 'Failed to load dashboard').toString(),
      );
    }
    final data = _asMap(root['data']);
    return DashboardData.fromJson(data);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}
