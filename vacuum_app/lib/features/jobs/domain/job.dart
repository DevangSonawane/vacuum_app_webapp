class Job {
  const Job({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.category,
    required this.clientName,
    required this.technicianName,
    required this.amount,
    required this.raisedDate,
    required this.scheduledDate,
    required this.closedDate,
    required this.description,
    this.clientId,
    this.technicianId,
    this.images = const [],
    this.reports = const [],
  });

  final String id;
  final String title;
  final String status; // Raised | Assigned | In Progress | Closed
  final String priority; // Low | Medium | High | Critical
  final String category;
  final String clientName;
  final String technicianName;
  final num amount;
  final String? raisedDate;
  final String? scheduledDate;
  final String? closedDate;
  final String description;
  final int? clientId;
  final int? technicianId;
  final List<JobImage> images;
  final List<JobReport> reports;

  static Job fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    num n(Object? v) => v is num ? v : num.tryParse(s(v)) ?? 0;
    List<dynamic> l(Object? v) => v is List ? v : const [];

    return Job(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
      priority: s(json['priority']),
      category: s(json['category']),
      clientName: s(json['client_name']),
      technicianName: s(json['technician_name']),
      amount: n(json['amount']),
      raisedDate: json['raised_date']?.toString(),
      scheduledDate: json['scheduled_date']?.toString(),
      closedDate: json['closed_date']?.toString(),
      description: s(json['description']),
      clientId: (json['client_id'] as num?)?.toInt(),
      technicianId: (json['technician_id'] as num?)?.toInt(),
      images: l(json['images'])
          .whereType<Map>()
          .map(
            (e) =>
                JobImage.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
          )
          .toList(),
      reports: l(json['reports'])
          .whereType<Map>()
          .map(
            (e) =>
                JobReport.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
          )
          .toList(),
    );
  }
}

class JobImage {
  const JobImage({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });

  final int id;
  final String fileUrl;
  final String fileName;

  static JobImage fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return JobImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileUrl: s(json['file_url']),
      fileName: s(json['file_name']),
    );
  }
}

class JobReport {
  const JobReport({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  static JobReport fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return JobReport(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
    );
  }
}
