class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.specialization,
    required this.status,
    required this.email,
    required this.joinDate,
    required this.jobsCompleted,
    required this.rating,
  });

  final int id;
  final String name;
  final String phone;
  final String specialization;
  final String status; // Active | On Leave | Inactive
  final String email;
  final String? joinDate;
  final int jobsCompleted;
  final double rating;

  static Technician fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    double d(Object? v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(s(v)) ?? 0.0;
    }

    final statusValue = s(json['status']);
    return Technician(
      id: i(json['id']),
      name: s(json['name']),
      phone: s(json['phone']),
      specialization: s(json['specialization']),
      status: statusValue.isEmpty ? 'Active' : statusValue,
      email: s(json['email']),
      joinDate: json['join_date']?.toString(),
      jobsCompleted: i(json['jobs_completed']),
      rating: d(json['rating']),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
  };

  Map<String, dynamic> toUpdatePayload() => {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
  };
}
