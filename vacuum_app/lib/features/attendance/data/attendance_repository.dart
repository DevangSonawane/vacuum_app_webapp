import 'package:dio/dio.dart';

import '../domain/attendance_entry.dart';

class AttendanceRepository {
  AttendanceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AttendanceEntry>> fetchByDate(String date) async {
    final res = await _dio.get('attendance', queryParameters: {'date': date});
    final root = _asMap(res.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .map((e) => AttendanceEntry.fromJson(e, fallbackDate: date))
        .toList();
  }

  Future<void> markAttendance(Map<String, dynamic> payload) async {
    await _dio.post('attendance', data: payload);
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
