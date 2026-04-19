class AmcContract {
  const AmcContract({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.value,
    required this.renewalReminderDays,
    required this.services,
    required this.nextServiceDate,
  });

  final String id;
  final String title;
  final int clientId;
  final String clientName;
  final String status; // Active | Expiring Soon | Expired
  final String? startDate;
  final String? endDate;
  final num value;
  final int renewalReminderDays;
  final List<String> services;
  final String? nextServiceDate;

  static AmcContract fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    num n(Object? v) => v is num ? v : num.tryParse(s(v)) ?? 0;
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    List<dynamic> l(Object? v) => v is List ? v : const [];

    return AmcContract(
      id: s(json['id']),
      title: s(json['title']),
      clientId: i(json['client_id']),
      clientName: s(json['client_name']),
      status: s(json['status']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      value: n(json['value']),
      renewalReminderDays: i(json['renewal_reminder_days'] ?? 30),
      services: l(json['services']).map((e) => e.toString()).toList(),
      nextServiceDate: json['next_service_date']?.toString(),
    );
  }
}

