class AmcContract {
  const AmcContract({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.value,
    required this.renewalReminderDays,
    required this.services,
    required this.nextServiceDate,
    required this.lastServiceDate,
    required this.serviceDate1,
    required this.serviceDate2,
    required this.serviceDate3,
    required this.serviceDate4,
    required this.serviceDate5,
    required this.serviceDate6,
    required this.pumps,
    this.daysLeft,
    this.poNumber,
    this.visitCount,
    this.breakdownVisitCount,
    this.pumpsCount,
    this.perPumpPrice,
    this.totalPrice,
    this.gstPercent,
  });

  final String id;
  final String title;
  final int clientId;
  final String clientName;
  final String? clientEmail;
  final String status; // Active | Expiring Soon | Expired
  final String? startDate;
  final String? endDate;
  final num value;
  final int renewalReminderDays;
  final List<String> services;
  final String? nextServiceDate;
  final String? lastServiceDate;
  final String? serviceDate1;
  final String? serviceDate2;
  final String? serviceDate3;
  final String? serviceDate4;
  final String? serviceDate5;
  final String? serviceDate6;
  final List<AmcPump> pumps;
  final int? daysLeft; // json: days_left
  final String? poNumber; // json: po_number
  final int? visitCount; // json: visit_count
  final int? breakdownVisitCount; // json: breakdown_visit_count
  final int? pumpsCount; // json: pumps_count
  final num? perPumpPrice; // json: per_pump_price
  final num? totalPrice; // json: total_price
  final num? gstPercent; // json: gst_percent

  static AmcContract fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    num n(Object? v) => v is num ? v : num.tryParse(s(v)) ?? 0;
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    int? iOrNull(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v));
    }

    num? nOrNull(Object? v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(s(v));
    }

    List<dynamic> l(Object? v) => v is List ? v : const [];

    return AmcContract(
      id: s(json['id']),
      title: s(json['title']),
      clientId: i(json['client_id']),
      clientName: s(json['client_name']),
      clientEmail: (json['client_email'] as Object?)?.toString(),
      status: s(json['status']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      value: n(json['value']),
      renewalReminderDays: i(json['renewal_reminder_days'] ?? 30),
      services: l(json['services']).map((e) => e.toString()).toList(),
      nextServiceDate: json['next_service_date']?.toString(),
      lastServiceDate: json['last_service_date']?.toString(),
      serviceDate1: json['service_date_1']?.toString(),
      serviceDate2: json['service_date_2']?.toString(),
      serviceDate3: json['service_date_3']?.toString(),
      serviceDate4: json['service_date_4']?.toString(),
      serviceDate5: json['service_date_5']?.toString(),
      serviceDate6: json['service_date_6']?.toString(),
      pumps: l(json['pumps'])
          .whereType<Map>()
          .map(
            (e) => AmcPump.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
          )
          .toList(),
      daysLeft: iOrNull(json['days_left']),
      poNumber: (json['po_number'] as Object?)?.toString(),
      visitCount: iOrNull(json['visit_count']),
      breakdownVisitCount: iOrNull(json['breakdown_visit_count']),
      pumpsCount: iOrNull(json['pumps_count']),
      perPumpPrice: nOrNull(json['per_pump_price']),
      totalPrice: nOrNull(json['total_price']),
      gstPercent: nOrNull(json['gst_percent']),
    );
  }
}

class AmcPump {
  const AmcPump({
    required this.id,
    required this.serialNumber,
    required this.modelNumber,
  });

  final String? id;
  final String serialNumber;
  final String modelNumber;

  static AmcPump fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return AmcPump(
      id: s(json['id']).isEmpty ? null : s(json['id']),
      serialNumber: s(json['serial_number']),
      modelNumber: s(json['model_number']),
    );
  }
}
