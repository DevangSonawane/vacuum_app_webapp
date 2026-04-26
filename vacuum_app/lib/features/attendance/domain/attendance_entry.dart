class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.specialization,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.hours,
  });

  final int id;
  final int technicianId;
  final String technicianName;
  final String specialization;
  final String date; // YYYY-MM-DD
  final String? checkIn;
  final String? checkOut;
  final String status; // Present | Late | Absent
  final num hours;

  static AttendanceEntry fromJson(
    Map<String, dynamic> json, {
    required String fallbackDate,
  }) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    return AttendanceEntry(
      id: i(json['id']),
      technicianId: i(json['technician_id']),
      technicianName: s(json['technician_name']).isNotEmpty
          ? s(json['technician_name'])
          : s(_asMap(json['technician'])['name']),
      specialization: s(json['specialization']).isNotEmpty
          ? s(json['specialization'])
          : s(_asMap(json['technician'])['specialization']),
      date: (json['date'] ?? fallbackDate).toString(),
      checkIn: (json['check_in'] as Object?)?.toString(),
      checkOut: (json['check_out'] as Object?)?.toString(),
      status: s(json['status']),
      hours: (json['hours'] as num?) ?? num.tryParse(s(json['hours'])) ?? 0,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }
}
