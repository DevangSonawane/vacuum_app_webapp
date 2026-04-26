import 'dart:convert';

class EmailSettings {
  const EmailSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.fromEmail,
    required this.fromName,
    required this.password,
    required this.notifications,
  });

  final String smtpHost;
  final String smtpPort;
  final String fromEmail;
  final String fromName;
  final String password;
  final EmailNotificationTriggers notifications;

  EmailSettings copyWith({
    String? smtpHost,
    String? smtpPort,
    String? fromEmail,
    String? fromName,
    String? password,
    EmailNotificationTriggers? notifications,
  }) {
    return EmailSettings(
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      password: password ?? this.password,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'smtpHost': smtpHost,
    'smtpPort': smtpPort,
    'fromEmail': fromEmail,
    'fromName': fromName,
    'password': password,
    'notifications': notifications.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  static EmailSettings fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    Map<String, dynamic> m(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
      return <String, dynamic>{};
    }

    return EmailSettings(
      smtpHost: s(json['smtpHost']),
      smtpPort: s(json['smtpPort']).isEmpty ? '587' : s(json['smtpPort']),
      fromEmail: s(json['fromEmail']),
      fromName: s(json['fromName']).isEmpty
          ? 'VDTI Service Hub'
          : s(json['fromName']),
      password: s(json['password']),
      notifications: EmailNotificationTriggers.fromJson(
        m(json['notifications']),
      ),
    );
  }

  static EmailSettings fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final json = decoded.map((k, v) => MapEntry(k.toString(), v));
        return EmailSettings.fromJson(json);
      }
    } catch (_) {}
    return EmailSettings.defaults;
  }

  static const defaults = EmailSettings(
    smtpHost: '',
    smtpPort: '587',
    fromEmail: '',
    fromName: 'VDTI Service Hub',
    password: '',
    notifications: EmailNotificationTriggers.defaults,
  );
}

class EmailNotificationTriggers {
  const EmailNotificationTriggers({
    required this.jobRaised,
    required this.jobAssigned,
    required this.jobCompleted,
    required this.reportApproved,
    required this.amcRenewal,
    required this.quotationSent,
  });

  final bool jobRaised;
  final bool jobAssigned;
  final bool jobCompleted;
  final bool reportApproved;
  final bool amcRenewal;
  final bool quotationSent;

  EmailNotificationTriggers copyWith({
    bool? jobRaised,
    bool? jobAssigned,
    bool? jobCompleted,
    bool? reportApproved,
    bool? amcRenewal,
    bool? quotationSent,
  }) {
    return EmailNotificationTriggers(
      jobRaised: jobRaised ?? this.jobRaised,
      jobAssigned: jobAssigned ?? this.jobAssigned,
      jobCompleted: jobCompleted ?? this.jobCompleted,
      reportApproved: reportApproved ?? this.reportApproved,
      amcRenewal: amcRenewal ?? this.amcRenewal,
      quotationSent: quotationSent ?? this.quotationSent,
    );
  }

  Map<String, dynamic> toJson() => {
    'jobRaised': jobRaised,
    'jobAssigned': jobAssigned,
    'jobCompleted': jobCompleted,
    'reportApproved': reportApproved,
    'amcRenewal': amcRenewal,
    'quotationSent': quotationSent,
  };

  static EmailNotificationTriggers fromJson(Map<String, dynamic> json) {
    bool b(Object? v) => v == true || v?.toString() == 'true';
    return EmailNotificationTriggers(
      jobRaised: b(json['jobRaised']),
      jobAssigned: b(json['jobAssigned']),
      jobCompleted: b(json['jobCompleted']),
      reportApproved: b(json['reportApproved']),
      amcRenewal: b(json['amcRenewal']),
      quotationSent: b(json['quotationSent']),
    );
  }

  static const defaults = EmailNotificationTriggers(
    jobRaised: true,
    jobAssigned: true,
    jobCompleted: true,
    reportApproved: true,
    amcRenewal: true,
    quotationSent: true,
  );
}
