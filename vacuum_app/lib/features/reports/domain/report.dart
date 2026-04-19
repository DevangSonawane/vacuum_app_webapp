class Report {
  const Report({
    required this.id,
    required this.title,
    required this.status,
    required this.jobId,
    required this.jobTitle,
    required this.clientName,
    required this.technicianName,
    required this.reportDate,
    required this.findings,
    required this.recommendations,
    required this.approvedAt,
    this.imageCount = 0,
    this.images = const [],
  });

  final String id;
  final String title;
  final String status; // Pending | Approved | Rejected
  final String jobId;
  final String jobTitle;
  final String clientName;
  final String technicianName;
  final String? reportDate;
  final String findings;
  final String recommendations;
  final String? approvedAt;
  final int imageCount;
  final List<ReportImage> images;

  static Report fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    List<dynamic> l(Object? v) => v is List ? v : const [];

    return Report(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
      jobId: s(json['job_id']),
      jobTitle: s(json['job_title']),
      clientName: s(json['client_name']),
      technicianName: s(json['technician_name']),
      reportDate: json['report_date']?.toString(),
      findings: s(json['findings']),
      recommendations: s(json['recommendations']),
      approvedAt: json['approved_at']?.toString(),
      imageCount: i(json['image_count']),
      images: l(json['images'])
          .whereType<Map>()
          .map((e) => ReportImage.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList(),
    );
  }
}

class ReportImage {
  const ReportImage({required this.id, required this.fileUrl, required this.fileName});

  final int id;
  final String fileUrl;
  final String fileName;

  static ReportImage fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return ReportImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileUrl: s(json['file_url']),
      fileName: s(json['file_name']),
    );
  }
}

