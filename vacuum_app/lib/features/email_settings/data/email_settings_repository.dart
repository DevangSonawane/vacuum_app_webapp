import 'package:dio/dio.dart';

import '../domain/email_settings.dart';

class EmailSettingsRepository {
  EmailSettingsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<EmailSettings> fetch() async {
    final res = await _dio.get('email-settings');
    final root = _asMap(res.data);
    final data = _asMap(root['data']);
    if (data.isEmpty) return EmailSettings.defaults;

    final notifications = _asMap(data['notifications']);
    return EmailSettings(
      smtpHost: (data['smtp_host'] ?? '').toString(),
      smtpPort: (data['smtp_port'] ?? '').toString().isEmpty
          ? '587'
          : (data['smtp_port'] ?? '').toString(),
      fromEmail: (data['from_email'] ?? '').toString(),
      fromName: ((data['from_name'] ?? '') as Object?)?.toString().trim().isEmpty ==
              true
          ? 'VDTI Service Hub'
          : (data['from_name'] ?? 'VDTI Service Hub').toString(),
      password: '',
      notifications: EmailNotificationTriggers(
        jobRaised: _b(notifications['job_raised']),
        jobAssigned: _b(notifications['job_assigned']),
        jobCompleted: _b(notifications['job_completed']),
        reportApproved: _b(notifications['report_approved']),
        amcRenewal: _b(notifications['amc_renewal']),
        quotationSent: _b(notifications['quotation_sent']),
      ),
    );
  }

  Future<EmailSettings> upsert(EmailSettings settings) async {
    final payload = <String, dynamic>{
      'smtp_host': settings.smtpHost.trim(),
      'smtp_port': int.tryParse(settings.smtpPort.trim()) ?? 587,
      'from_email': settings.fromEmail.trim(),
      'from_name': settings.fromName.trim().isEmpty
          ? 'VDTI Service Hub'
          : settings.fromName.trim(),
      if (settings.password.trim().isNotEmpty)
        'smtp_password': settings.password,
      'notifications': {
        'job_raised': settings.notifications.jobRaised,
        'job_assigned': settings.notifications.jobAssigned,
        'job_completed': settings.notifications.jobCompleted,
        'report_approved': settings.notifications.reportApproved,
        'amc_renewal': settings.notifications.amcRenewal,
        'quotation_sent': settings.notifications.quotationSent,
      },
    };

    final res = await _dio.put('email-settings', data: payload);
    final root = _asMap(res.data);
    final data = _asMap(root['data']);
    if (data.isEmpty) return settings.copyWith(password: '');

    final notifications = _asMap(data['notifications']);
    return EmailSettings(
      smtpHost: (data['smtp_host'] ?? settings.smtpHost).toString(),
      smtpPort: (data['smtp_port'] ?? settings.smtpPort).toString(),
      fromEmail: (data['from_email'] ?? settings.fromEmail).toString(),
      fromName: (data['from_name'] ?? settings.fromName).toString(),
      password: '',
      notifications: EmailNotificationTriggers(
        jobRaised: _b(notifications['job_raised']),
        jobAssigned: _b(notifications['job_assigned']),
        jobCompleted: _b(notifications['job_completed']),
        reportApproved: _b(notifications['report_approved']),
        amcRenewal: _b(notifications['amc_renewal']),
        quotationSent: _b(notifications['quotation_sent']),
      ),
    );
  }

  Future<void> sendTestEmail(String to) async {
    await _dio.post('email-settings/test', data: {'to': to.trim()});
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

bool _b(Object? v) => v == true || v?.toString() == 'true';

