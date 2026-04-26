class Client {
  const Client({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    this.gstNo = '',
    required this.address,
    required this.type,
    required this.status,
    required this.contractValue,
    required this.joinDate,
    this.stats,
  });

  final int id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String gstNo; // json: gst_no
  final String address;
  final String
  type; // Corporate | Residential | Commercial | Healthcare | Government
  final String status; // Active | Inactive
  final num contractValue;
  final String? joinDate;
  final ClientStats? stats;

  static Client fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    num n(Object? v) => v is num ? v : num.tryParse(s(v)) ?? 0;

    final rawType = s(json['type']);
    final rawStatus = s(json['status']);

    return Client(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: s(json['name']),
      contactPerson: s(json['contact_person']),
      email: s(json['email']),
      phone: s(json['phone']),
      gstNo: s(json['gst_no']),
      address: s(json['address']),
      type: rawType.isEmpty ? 'Corporate' : rawType,
      status: rawStatus.isEmpty ? 'Active' : rawStatus,
      contractValue: n(json['contract_value']),
      joinDate: json['join_date']?.toString(),
      stats: json['stats'] != null
          ? ClientStats.fromJson(_asMap(json['stats']))
          : null,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  Map<String, dynamic> toPayload() => {
    'name': name,
    'contact_person': contactPerson,
    'type': type,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (phone.isNotEmpty) 'phone': phone,
    if (address.isNotEmpty) 'address': address,
    if (gstNo.isNotEmpty) 'gst_no': gstNo,
    if (contractValue > 0) 'contract_value': contractValue,
  };
}

class ClientStats {
  const ClientStats({
    required this.totalJobs,
    required this.openJobs,
    required this.activeAmcCount,
  });

  final int totalJobs;
  final int openJobs;
  final int activeAmcCount;

  static ClientStats fromJson(Map<String, dynamic> json) {
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return ClientStats(
      totalJobs: i(json['total_jobs']),
      openJobs: i(json['open_jobs']),
      activeAmcCount: i(json['active_amc_count']),
    );
  }
}
