class AttendanceRecord {
  const AttendanceRecord({
    required this.employeeId,
    required this.employeeType,
    required this.date,
    required this.statusDescription,
    required this.statusCode,
    required this.checkIn,
    required this.checkOut,
    required this.leaveTypeDescription,
    required this.leaveTypeCode,
    required this.remarks,
    required this.requestedStatusDescription,
    required this.requestedLeaveTypeDescription,
    required this.requestedCheckIn,
    required this.requestedCheckOut,
  });

  final String? employeeId;
  final String? employeeType;
  final String? date;
  final String? statusDescription;
  final int? statusCode;
  final String? checkIn;
  final String? checkOut;
  final String? leaveTypeDescription;
  final int? leaveTypeCode;
  final String? remarks;
  final String? requestedStatusDescription;
  final String? requestedLeaveTypeDescription;
  final String? requestedCheckIn;
  final String? requestedCheckOut;

  static AttendanceRecord fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int? i(Object? v) {
      if (v == null || v.toString().trim().isEmpty) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v));
    }

    Map<String, dynamic> mapOf(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
      return <String, dynamic>{};
    }

    final status = mapOf(json['status']);
    final leaveType = mapOf(json['leave-type'] ?? json['leave_type']);
    final requestedStatus = mapOf(json['requested-status'] ?? json['requested_status']);
    final requestedLeaveType = mapOf(json['requested-leave-type'] ?? json['requested_leave_type']);

    return AttendanceRecord(
      employeeId: json['employee-id']?.toString() ?? json['employee_id']?.toString(),
      employeeType: json['employee-type']?.toString() ?? json['employee_type']?.toString(),
      date: json['date']?.toString(),
      statusDescription: status['description']?.toString(),
      statusCode: i(status['code']),
      checkIn: json['check-in']?.toString() ?? json['check_in']?.toString(),
      checkOut: json['check-out']?.toString() ?? json['check_out']?.toString(),
      leaveTypeDescription: leaveType['description']?.toString(),
      leaveTypeCode: i(leaveType['code']),
      remarks: json['remarks']?.toString(),
      requestedStatusDescription: requestedStatus['description']?.toString(),
      requestedLeaveTypeDescription: requestedLeaveType['description']?.toString(),
      requestedCheckIn: json['requested-check-in']?.toString() ?? json['requested_check_in']?.toString(),
      requestedCheckOut: json['requested-check-out']?.toString() ?? json['requested_check_out']?.toString(),
    );
  }
}
