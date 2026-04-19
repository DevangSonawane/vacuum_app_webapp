import 'package:dio/dio.dart';

import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({List<AppNotification> items, int unreadCount})> fetch({int limit = 30}) async {
    final response = await _dio.get('/notifications', queryParameters: {'limit': limit});
    final root = _asMap(response.data);

    final unread = _asInt(root['unread_count']);
    final data = _asList(root['data']);
    final items = <AppNotification>[
      for (final row in data) _fromRow(_asMap(row)),
    ];

    return (items: items, unreadCount: unread);
  }

  Future<void> markAllRead() async {
    await _dio.patch('/notifications/read', data: {});
  }

  Future<void> markRead(List<int> ids) async {
    await _dio.patch('/notifications/read', data: {'ids': ids});
  }

  Future<void> clearAll() async {
    await _dio.delete('/notifications');
  }

  static AppNotification _fromRow(Map<String, dynamic> row) {
    final id = _asInt(row['id']);
    final event = (row['event'] ?? '').toString();
    final title = (row['title'] ?? '').toString();
    final message = (row['message'] ?? '').toString();
    final entityType = (row['entity_type'] as Object?)?.toString();
    final entityId = (row['entity_id'] as Object?)?.toString();
    final createdAt = (row['created_at'] ?? '').toString();
    final ts = _parseTime(createdAt) ?? DateTime.now();
    final read = row['is_read'] == true || row['is_read']?.toString() == 'true';

    final meta = notificationMeta(event);
    return AppNotification(
      id: id.toString(),
      serverId: id,
      event: event,
      title: title.isNotEmpty ? title : meta.title,
      message: message,
      entityType: entityType,
      entityId: entityId,
      timestamp: ts,
      read: read,
      fromDb: true,
    );
  }

  static DateTime? _parseTime(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(Object? v) => v is List ? v : const [];
  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}

