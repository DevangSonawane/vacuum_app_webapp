class Technician {
  const Technician({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.specialization,
    required this.status,
    required this.email,
    required this.joinDate,
    required this.jobsCompleted,
    required this.rating,
    required this.avatar,
    required this.recentJobs,
    required this.documents,
  });

  final int id;
  final int userId;
  final String name;
  final String phone;
  final String specialization;
  final String status; // Active | On Leave | Inactive
  final String email;
  final String? joinDate;
  final int jobsCompleted;
  final double rating;
  final String avatar;
  final List<TechnicianRecentJob> recentJobs;
  final List<TechnicianDocument> documents;

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
    final phone = s(json['phone']).isNotEmpty
        ? s(json['phone'])
        : s(json['phone_number']);
    return Technician(
      id: i(json['id']),
      userId: i(json['user_id']),
      name: s(json['name']),
      phone: phone,
      specialization: s(json['specialization']),
      status: statusValue.isEmpty ? 'Active' : statusValue,
      email: s(json['email']),
      joinDate: json['join_date']?.toString(),
      jobsCompleted: i(json['jobs_completed']),
      rating: d(json['rating']),
      avatar: s(json['avatar']),
      recentJobs: _asList(json['recent_jobs'])
          .whereType<Map>()
          .map((e) => TechnicianRecentJob.fromJson(_asMap(e)))
          .toList(),
      documents: _asList(json['documents'])
          .whereType<Map>()
          .map((e) => TechnicianDocument.fromJson(_asMap(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toCreatePayload({
    String? password,
    List<Map<String, dynamic>> documents = const [],
  }) =>
      {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
    if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
    if (documents.isNotEmpty) 'documents': documents,
  };

  Map<String, dynamic> toUpdatePayload() => {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
  };

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) => value is List ? value : const [];
}

class TechnicianRecentJob {
  const TechnicianRecentJob({
    required this.id,
    required this.title,
    required this.status,
    required this.closedDate,
  });

  final String id;
  final String title;
  final String status;
  final String? closedDate;

  factory TechnicianRecentJob.fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    return TechnicianRecentJob(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
      closedDate: json['closed_date']?.toString(),
    );
  }
}

class TechnicianDocument {
  const TechnicianDocument({
    required this.id,
    required this.documentType,
    required this.documentName,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.expiryDate,
    required this.notes,
    required this.expiryStatus,
    required this.uploadedByName,
  });

  final int id;
  final String documentType;
  final String documentName;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSizeBytes;
  final String? expiryDate;
  final String notes;
  final String expiryStatus;
  final String uploadedByName;

  factory TechnicianDocument.fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    return TechnicianDocument(
      id: i(json['id']),
      documentType: s(json['document_type']),
      documentName: s(json['document_name']),
      fileName: s(json['file_name']),
      fileUrl: s(json['file_url']),
      mimeType: s(json['mime_type']),
      fileSizeBytes: i(json['file_size_bytes']),
      expiryDate: json['expiry_date']?.toString(),
      notes: s(json['notes']),
      expiryStatus: s(json['expiry_status']),
      uploadedByName: s(json['uploaded_by_name']),
    );
  }
}

class TechnicianRating {
  const TechnicianRating({
    required this.id,
    required this.rating,
    required this.review,
    required this.jobId,
    required this.ratedByName,
    required this.createdAt,
  });

  final int id;
  final double rating;
  final String review;
  final String jobId;
  final String ratedByName;
  final String? createdAt;

  factory TechnicianRating.fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    double d(Object? v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(s(v)) ?? 0.0;
    }

    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    return TechnicianRating(
      id: i(json['id']),
      rating: d(json['rating']),
      review: s(json['review']),
      jobId: s(json['job_id']),
      ratedByName: s(json['rated_by_name']),
      createdAt: json['created_at']?.toString(),
    );
  }
}
