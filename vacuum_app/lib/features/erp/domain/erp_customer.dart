class ErpCustomer {
  const ErpCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.address,
    this.gstin,
    this.createdDate,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final String status;
  final String? createdDate;

  static ErpCustomer fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    String? sn(Object? v) {
      final v0 = (v ?? '').toString().trim();
      return v0.isEmpty ? null : v0;
    }

    return ErpCustomer(
      id: s(json['id']).trim(),
      name: s(json['name']).trim(),
      email: sn(json['email']),
      phone: sn(json['phone']),
      address: sn(json['address']),
      gstin: sn(json['gstin'] ?? json['gst_no']),
      status: s(json['status']).trim().isEmpty ? 'Active' : s(json['status']),
      createdDate: sn(json['created_date']),
    );
  }
}

