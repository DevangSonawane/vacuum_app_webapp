class AttendanceLeaveResponse {
  const AttendanceLeaveResponse({
    required this.success,
    required this.email,
    required this.from,
    required this.to,
    required this.records,
    required this.rawLeave,
  });

  final bool success;
  final String? email;
  final String? from;
  final String? to;
  final List<AttendanceLeaveRecord> records;
  final Map<String, dynamic> rawLeave;

  static AttendanceLeaveResponse fromJson(Map<String, dynamic> json) {
    bool b(Object? v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final value = v.toString().trim().toLowerCase();
      return value == 'true' || value == '1' || value == 'yes';
    }

    Map<String, dynamic> mapOf(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
      return <String, dynamic>{};
    }

    final leave = json['leave'] ?? json['data'] ?? json;
    final leaveMap = leave is Map
        ? mapOf(leave)
        : <String, dynamic>{'items': leave};

    return AttendanceLeaveResponse(
      success: b(json['success'], fallback: true),
      email: json['email']?.toString(),
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      records: _extractRecords(leave),
      rawLeave: leaveMap,
    );
  }

  static List<AttendanceLeaveRecord> _extractRecords(dynamic leave) {
    Map<String, dynamic> mapOf(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
      return <String, dynamic>{};
    }

    AttendanceLeaveRecord recordFrom(dynamic value, {String? fallbackLabel}) {
      if (value is Map || value is Map<String, dynamic>) {
        return AttendanceLeaveRecord.fromJson(
          mapOf(value),
          fallbackLabel: fallbackLabel,
        );
      }
      return AttendanceLeaveRecord.fromJson(<String, dynamic>{
        'value': value,
      }, fallbackLabel: fallbackLabel);
    }

    if (leave is List) {
      return leave
          .where((item) => item != null)
          .map((item) => recordFrom(item))
          .toList();
    }

    final leaveMap = mapOf(leave);
    for (final key in const [
      'records',
      'items',
      'data',
      'leaves',
      'leave_records',
      'leave-records',
    ]) {
      final candidate = leaveMap[key];
      if (candidate is List) {
        return candidate
            .where((item) => item != null)
            .map((item) => recordFrom(item, fallbackLabel: key))
            .toList();
      }
    }

    if (leaveMap.isEmpty) {
      return const [];
    }

    final flattened = <AttendanceLeaveRecord>[];
    var sawStructured = false;

    for (final entry in leaveMap.entries) {
      final value = entry.value;
      if (value is List) {
        sawStructured = true;
        for (final item in value) {
          if (item == null) continue;
          flattened.add(recordFrom(item, fallbackLabel: entry.key));
        }
      } else if (value is Map) {
        sawStructured = true;
        flattened.add(recordFrom(value, fallbackLabel: entry.key));
      }
    }

    if (sawStructured && flattened.isNotEmpty) {
      return flattened;
    }

    return [AttendanceLeaveRecord.fromJson(leaveMap)];
  }
}

class AttendanceLeaveRecord {
  const AttendanceLeaveRecord({
    required this.title,
    required this.from,
    required this.to,
    required this.status,
    required this.type,
    required this.reason,
    required this.days,
    required this.appliedOn,
    required this.approvedBy,
    required this.remarks,
    required this.rawData,
  });

  final String title;
  final String? from;
  final String? to;
  final String? status;
  final String? type;
  final String? reason;
  final String? days;
  final String? appliedOn;
  final String? approvedBy;
  final String? remarks;
  final Map<String, dynamic> rawData;

  static AttendanceLeaveRecord fromJson(
    Map<String, dynamic> json, {
    String? fallbackLabel,
  }) {
    String pick(List<String> keys, {String? fallback}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback ?? '';
    }

    final title = pick(const [
      'description',
      'title',
      'name',
      'leave_type',
      'leave-type',
      'type',
      'status',
      'reason',
    ], fallback: fallbackLabel ?? 'Leave');

    return AttendanceLeaveRecord(
      title: title,
      from: pick(const [
        'from',
        'start_date',
        'start-date',
        'start',
        'leave_from',
        'leave-from',
      ]).ifEmptyNull,
      to: pick(const [
        'to',
        'end_date',
        'end-date',
        'end',
        'leave_to',
        'leave-to',
      ]).ifEmptyNull,
      status: pick(const ['status', 'state', 'approval_status']).ifEmptyNull,
      type: pick(const ['leave_type', 'leave-type', 'type']).ifEmptyNull,
      reason: pick(const [
        'reason',
        'description',
        'remarks',
        'note',
        'comment',
      ]).ifEmptyNull,
      days: pick(const [
        'days',
        'count',
        'no_of_days',
        'number_of_days',
      ]).ifEmptyNull,
      appliedOn: pick(const [
        'applied_on',
        'applied-on',
        'created_at',
        'created-at',
        'date',
      ]).ifEmptyNull,
      approvedBy: pick(const [
        'approved_by',
        'approved-by',
        'approver',
      ]).ifEmptyNull,
      remarks: pick(const ['remarks', 'note', 'comment']).ifEmptyNull,
      rawData: Map<String, dynamic>.from(json),
    );
  }
}

extension on String {
  String? get ifEmptyNull => trim().isEmpty ? null : this;
}
