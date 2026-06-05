import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_entry.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(dio: ref.read(dioProvider));
});

class AttendanceDaySummary {
  const AttendanceDaySummary({
    required this.date,
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
  });

  final String date; // YYYY-MM-DD
  final int present;
  final int late;
  final int absent;
  final int total;
}

class AttendanceState {
  const AttendanceState({
    required this.date,
    required this.items,
    required this.week,
  });

  final DateTime date;
  final List<AttendanceEntry> items;
  final List<AttendanceDaySummary> week;

  AttendanceState copyWith({
    DateTime? date,
    List<AttendanceEntry>? items,
    List<AttendanceDaySummary>? week,
  }) => AttendanceState(
    date: date ?? this.date,
    items: items ?? this.items,
    week: week ?? this.week,
  );
}

final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, AttendanceState>(
      AttendanceNotifier.new,
    );

class AttendanceNotifier extends AsyncNotifier<AttendanceState> {
  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);

  @override
  Future<AttendanceState> build() async {
    final now = DateTime.now();
    return _loadForDateSafe(now);
  }

  Future<void> setDate(DateTime date) async {
    state = const AsyncLoading();
    state = AsyncData(await _loadForDateSafe(date));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncLoading();
    state = AsyncData(await _loadForDateSafe(current.date));
  }

  Future<bool> markAttendance(Map<String, dynamic> payload) async {
    try {
      await _repo.markAttendance(payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AttendanceState> _loadForDate(DateTime date) async {
    final dateKey = _fmtDate(date);
    final items = await _repo.fetchByDate(dateKey);
    final week = await _fetchWeek(date);
    return AttendanceState(date: date, items: items, week: week);
  }

  Future<AttendanceState> _loadForDateSafe(DateTime date) async {
    try {
      return await _loadForDate(date);
    } catch (_) {
      return AttendanceState(
        date: date,
        items: const [],
        week: await _fetchWeek(date),
      );
    }
  }

  Future<List<AttendanceDaySummary>> _fetchWeek(DateTime anchor) async {
    final days = [
      for (var i = 6; i >= 0; i--) anchor.subtract(Duration(days: i)),
    ];

    final summaries = <AttendanceDaySummary>[];
    for (final d in days) {
      final dateKey = _fmtDate(d);
      try {
        final entries = await _repo.fetchByDate(dateKey);
        final present = entries.where((e) => e.status == 'Present').length;
        final late = entries.where((e) => e.status == 'Late').length;
        final absent = entries.where((e) => e.status == 'Absent').length;
        final total = entries.map((e) => e.technicianId).toSet().length;
        summaries.add(
          AttendanceDaySummary(
            date: dateKey,
            present: present,
            late: late,
            absent: absent,
            total: total,
          ),
        );
      } catch (_) {
        summaries.add(
          AttendanceDaySummary(
            date: dateKey,
            present: 0,
            late: 0,
            absent: 0,
            total: 0,
          ),
        );
      }
    }
    return summaries;
  }

  static final _apiFmt = DateFormat('yyyy-MM-dd');
  static String _fmtDate(DateTime d) => _apiFmt.format(d);
}
