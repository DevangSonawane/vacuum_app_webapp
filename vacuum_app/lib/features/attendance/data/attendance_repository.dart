import 'package:dio/dio.dart';

import '../domain/attendance_employee.dart';
import '../domain/attendance_entry.dart';
import '../domain/attendance_record.dart';

class AttendanceRepository {
  AttendanceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AttendanceEntry>> fetchByDate(String date) async {
    try {
      final res = await _dio.get('attendance', queryParameters: {'date': date});
      final root = _asMap(res.data);
      final list = _asList(root['data']);
      return list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map((e) => AttendanceEntry.fromJson(e, fallbackDate: date))
          .toList();
    } on DioException catch (err) {
      final status = err.response?.statusCode;
      if (status == 404 || status == 204 || status == 400) return [];
      return [];
    }
  }

  Future<void> markAttendance(Map<String, dynamic> payload) async {
    await _dio.post('attendance', data: payload);
  }

  Future<List<AttendanceEmployee>> fetchEmployees() async {
    try {
      final res = await _dio.get('attendance/people');
      final root = _asMap(res.data);
      final list = _asList(root['employees'] ?? root['data']);
      return list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(AttendanceEmployee.fromJson)
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<AttendanceEmployee?> fetchEmployee(String employeeId) async {
    try {
      final res = await _dio.get('attendance/people/$employeeId');
      final root = _asMap(res.data);
      final employee = _asMap(root['employee'] ?? root['data'] ?? root);
      return AttendanceEmployee.fromJson(employee);
    } on DioException {
      return null;
    }
  }

  Future<AttendanceEmployee?> fetchEmployeePreview(String employeeId) async {
    try {
      final res = await _dio.get('attendance/people/view/$employeeId');
      final root = _asMap(res.data);
      final employee = _asMap(root['employee'] ?? root['data'] ?? root);
      return AttendanceEmployee.fromJson(employee);
    } on DioException {
      return null;
    }
  }

  Future<void> storeEmployee({
    required String employeeId,
    required Map<String, dynamic> employee,
  }) async {
    await _dio.post(
      'attendance/people',
      data: {'employee_id': employeeId, 'employee': employee},
    );
  }

  Future<void> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> payload,
  }) async {
    await _dio.put('attendance/people/$employeeId', data: payload);
  }

  Future<void> setEmployeeSalary({
    required String employeeId,
    required num annualCtc,
    bool customSalaryStructure = false,
  }) async {
    await _dio.post(
      'attendance/people/$employeeId/salary',
      data: {
        'annual-ctc': annualCtc,
        'custom-salary-structure': customSalaryStructure,
      },
    );
  }

  Future<AttendanceRecord?> fetchAttendanceRecord({
    required String email,
    required String date,
    String employeeType = 'employee',
  }) async {
    try {
      final res = await _dio.get(
        'attendance/fetch',
        queryParameters: {
          'email': email,
          'date': date,
          'employee_type': employeeType,
        },
      );
      final root = _asMap(res.data);
      final record = _asMap(root['attendance'] ?? root['data'] ?? root);
      if (record.isEmpty) return null;
      final nested = record['data'];
      final payload = nested is Map ? _asMap(nested) : record;
      return AttendanceRecord.fromJson(payload);
    } on DioException catch (err) {
      if (err.response?.statusCode == 404) return null;
      return null;
    }
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
