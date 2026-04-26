class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.action,
    required this.user,
    required this.entityId,
    required this.timestamp,
    required this.entityType,
    required this.performedAt,
  });

  final int id;
  final String
  type; // job | client | report | technician | amc | user | email_settings
  final String action;
  final String user;
  final String? entityId;
  final String timestamp;
  final String? entityType; // json: entity_type
  final String? performedAt; // json: performed_at (ISO timestamp)

  static ActivityItem fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    final performedAt = (json['performed_at'] ?? json['timestamp'])?.toString();

    return ActivityItem(
      id: i(json['id']),
      type: s(json['type']),
      action: s(json['action']),
      user: () {
        final pb = json['performed_by'];
        if (pb is Map) {
          return pb['name']?.toString() ?? '';
        }
        return (json['user'] ?? '').toString();
      }(),
      entityId: (json['entity_id'] as Object?)?.toString(),
      timestamp: performedAt ?? s(json['timestamp']),
      entityType: (json['entity_type'] as Object?)?.toString(),
      performedAt: performedAt,
    );
  }
}
