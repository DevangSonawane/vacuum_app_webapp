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
    this.companyName,
    this.contactPerson,
    this.modelSerialInstallation,
    this.operatingHoursPerDay,
    this.applicationProcessDescription,
    this.remarks,
    this.vdtRepresentativeName,
    this.clientRepresentativeName,
    this.checklistItems = const [],
    this.issueObservations = const [],
    this.mandatorySpares = const [],
    this.clientEmail,
    this.comments,
    this.poNumber,
    this.location,
    this.serialNo,
    this.clientId,
    this.technicalReportCount = 0,
    this.technicalReports = const [],
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
  final String? companyName; // json: company_name
  final String? contactPerson; // json: contact_person
  final String? modelSerialInstallation; // json: model_serial_installation
  final String? operatingHoursPerDay; // json: operating_hours_per_day
  final String? applicationProcessDescription; // json: application_process_description
  final String? remarks; // json: remarks
  final String? vdtRepresentativeName; // json: vdt_representative_name
  final String? clientRepresentativeName; // json: client_representative_name
  final List<ChecklistItem> checklistItems; // json: checklist_items
  final List<IssueObservation> issueObservations; // json: issue_observations
  final List<MandatorySpare> mandatorySpares; // json: mandatory_spares
  final String? clientEmail; // json: client_email
  final String? comments; // json: comments
  final String? poNumber; // json: po_number
  final String? location; // json: location
  final String? serialNo; // json: serial_no
  final String? clientId; // json: client_id
  final int technicalReportCount; // json: technical_report_count
  final List<TechnicalReportFile> technicalReports; // json: technical_reports
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
    Map<String, dynamic> m(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
      return <String, dynamic>{};
    }

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
      companyName: (json['company_name'] as Object?)?.toString(),
      contactPerson: (json['contact_person'] as Object?)?.toString(),
      modelSerialInstallation:
          (json['model_serial_installation'] as Object?)?.toString(),
      operatingHoursPerDay:
          (json['operating_hours_per_day'] as Object?)?.toString(),
      applicationProcessDescription:
          (json['application_process_description'] as Object?)?.toString(),
      remarks: (json['remarks'] as Object?)?.toString(),
      vdtRepresentativeName:
          (json['vdt_representative_name'] as Object?)?.toString(),
      clientRepresentativeName:
          (json['client_representative_name'] as Object?)?.toString(),
      checklistItems: l(json['checklist_items'])
          .whereType<Map>()
          .map((e) => ChecklistItem.fromJson(m(e)))
          .toList(),
      issueObservations: l(json['issue_observations'])
          .whereType<Map>()
          .map((e) => IssueObservation.fromJson(m(e)))
          .toList(),
      mandatorySpares: l(json['mandatory_spares'])
          .whereType<Map>()
          .map((e) => MandatorySpare.fromJson(m(e)))
          .toList(),
      clientEmail: (json['client_email'] as Object?)?.toString(),
      comments: (json['comments'] as Object?)?.toString(),
      poNumber: (json['po_number'] as Object?)?.toString(),
      location: (json['location'] as Object?)?.toString(),
      serialNo: (json['serial_no'] as Object?)?.toString(),
      clientId: (json['client_id'] as Object?)?.toString(),
      technicalReportCount: i(json['technical_report_count']),
      technicalReports: l(json['technical_reports'])
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(TechnicalReportFile.fromJson)
          .toList(),
      imageCount: i(json['image_count']),
      images: l(json['images'])
          .whereType<Map>()
          .map(
            (e) => ReportImage.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList(),
    );
  }
}

class ChecklistItem {
  const ChecklistItem({
    required this.sr,
    required this.description,
    required this.status,
  });

  final int sr;
  final String description;
  final String status;

  static ChecklistItem fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return ChecklistItem(
      sr: (json['sr'] as num?)?.toInt() ?? 0,
      description: s(json['description']),
      status: s(json['status']),
    );
  }
}

class IssueObservation {
  const IssueObservation({
    required this.sr,
    required this.issue,
    required this.observation,
    required this.impactOnPump,
    required this.severity,
    required this.recommendedSpares,
  });

  final int sr;
  final String issue;
  final String observation;
  final String impactOnPump; // json: impact_on_pump
  final String severity;
  final String recommendedSpares; // json: recommended_spares

  static IssueObservation fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return IssueObservation(
      sr: (json['sr'] as num?)?.toInt() ?? 0,
      issue: s(json['issue']),
      observation: s(json['observation']),
      impactOnPump: s(json['impact_on_pump']),
      severity: s(json['severity']),
      recommendedSpares: s(json['recommended_spares']),
    );
  }
}

class MandatorySpare {
  const MandatorySpare({
    required this.spareName,
    required this.pumpModel,
    required this.totalToOrder,
  });

  final String spareName; // json: spare_name
  final String pumpModel; // json: pump_model
  final String totalToOrder; // json: total_to_order

  static MandatorySpare fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return MandatorySpare(
      spareName: s(json['spare_name']),
      pumpModel: s(json['pump_model']),
      totalToOrder: s(json['total_to_order']),
    );
  }
}

class ReportImage {
  const ReportImage({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });

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

class TechnicalReportFile {
  const TechnicalReportFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  final int id;
  final String fileName;
  final String fileUrl;
  final String? mimeType;
  final int? fileSizeBytes;

  static TechnicalReportFile fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return TechnicalReportFile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: s(json['file_name']),
      fileUrl: s(json['file_url']),
      mimeType: json['mime_type']?.toString(),
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
    );
  }
}
