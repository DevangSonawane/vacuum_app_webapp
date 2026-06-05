class AttendanceEmployee {
  const AttendanceEmployee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.dateOfHiring,
    required this.title,
    required this.department,
    required this.managerEmployeeId,
    required this.managerEmail,
    required this.pan,
    required this.bankIfsc,
    required this.bankAccountNumber,
    required this.annualCtc,
    required this.customSalaryStructure,
    required this.isActive,
    required this.userId,
    required this.technicianId,
    required this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.rawData,
  });

  final int? id;
  final String employeeId;
  final String name;
  final String email;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? dateOfHiring;
  final String title;
  final String department;
  final String? managerEmployeeId;
  final String? managerEmail;
  final String? pan;
  final String? bankIfsc;
  final String? bankAccountNumber;
  final num? annualCtc;
  final bool customSalaryStructure;
  final bool isActive;
  final int? userId;
  final int? technicianId;
  final String? lastSyncedAt;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> rawData;

  static AttendanceEmployee fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int? i(Object? v) {
      if (v == null || v.toString().trim().isEmpty) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v));
    }

    num? n(Object? v) {
      if (v == null || v.toString().trim().isEmpty) return null;
      if (v is num) return v;
      return num.tryParse(s(v));
    }

    bool b(Object? v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final value = s(v).toLowerCase();
      return value == 'true' || value == '1' || value == 'yes';
    }

    String? pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
      return null;
    }

    return AttendanceEmployee(
      id: i(json['id']),
      employeeId: pickString(['employee_id', 'employee-id']) ?? '',
      name: s(json['name']),
      email: s(json['email']),
      phoneNumber: pickString(['phone_number', 'phone-number']) ?? '',
      dateOfBirth: pickString(['date_of_birth', 'date-of-birth']),
      dateOfHiring: pickString(['date_of_hiring', 'date-of-hiring']),
      title: s(json['title']),
      department: s(json['department']),
      managerEmployeeId: pickString(['manager_employee_id', 'manager-employee-id']),
      managerEmail: pickString(['manager_email', 'manager-email']),
      pan: pickString(['pan']),
      bankIfsc: pickString(['bank_ifsc', 'bank-ifsc']),
      bankAccountNumber: pickString(['bank_account_number', 'bank-account-number']),
      annualCtc: n(json['annual_ctc'] ?? json['annual-ctc']),
      customSalaryStructure: b(json['custom_salary_structure'] ?? json['custom-salary-structure']),
      isActive: b(json['is_active'], fallback: true),
      userId: i(json['user_id']),
      technicianId: i(json['technician_id']),
      lastSyncedAt: pickString(['last_synced_at', 'last-synced-at']),
      createdAt: pickString(['created_at', 'created-at']),
      updatedAt: pickString(['updated_at', 'updated-at']),
      rawData: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toStorePayload() => {
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'date-of-birth': dateOfBirth,
    'date-of-hiring': dateOfHiring,
    'title': title,
    'department': department,
    'manager-employee-id': managerEmployeeId,
    'manager-email': managerEmail,
    'pan': pan,
    'bank-ifsc': bankIfsc,
    'bank-account-number': bankAccountNumber,
    'is_active': isActive,
  }..removeWhere((key, value) => value == null);
}
