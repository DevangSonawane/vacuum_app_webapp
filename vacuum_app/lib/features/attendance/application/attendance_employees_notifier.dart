import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_employee.dart';

final attendanceEmployeesRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(dio: ref.read(dioProvider));
});

final attendanceEmployeesProvider =
    AsyncNotifierProvider<AttendanceEmployeesNotifier, List<AttendanceEmployee>>(
      AttendanceEmployeesNotifier.new,
    );

class AttendanceEmployeesNotifier
    extends AsyncNotifier<List<AttendanceEmployee>> {
  AttendanceRepository get _repo => ref.read(attendanceEmployeesRepositoryProvider);

  @override
  Future<List<AttendanceEmployee>> build() async {
    return _loadSafe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadSafe());
  }

  Future<AttendanceEmployee?> previewEmployee(String employeeId) async {
    return _repo.fetchEmployeePreview(employeeId);
  }

  Future<bool> storeEmployee({
    required String employeeId,
    required AttendanceEmployee employee,
  }) async {
    try {
      await _repo.storeEmployee(
        employeeId: employeeId,
        employee: employee.toStorePayload(),
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _repo.updateEmployee(employeeId: employeeId, payload: payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setSalary({
    required String employeeId,
    required num annualCtc,
    required bool customSalaryStructure,
  }) async {
    try {
      await _repo.setEmployeeSalary(
        employeeId: employeeId,
        annualCtc: annualCtc,
        customSalaryStructure: customSalaryStructure,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AttendanceEmployee>> _loadSafe() async {
    try {
      return await _repo.fetchEmployees();
    } catch (_) {
      return const [];
    }
  }
}
