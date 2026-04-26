class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String role; // admin, manager, engineer, technician, staff, labour
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value) => value == null ? '' : value.toString();
    bool readBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: readString(json['first_name'] ?? json['firstName']),
      lastName: readString(json['last_name'] ?? json['lastName']),
      email: readString(json['email']),
      phoneNumber: (json['phone_number'] ?? json['phoneNumber'])?.toString(),
      role: readString(json['role']),
      isActive: readBool(json['is_active'] ?? json['isActive'] ?? true),
    );
  }
}
