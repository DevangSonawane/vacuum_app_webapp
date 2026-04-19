class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.action,
    required this.user,
    required this.entityId,
    required this.timestamp,
  });

  final int id;
  final String type; // job | client | report | technician | amc | user | email_settings
  final String action;
  final String user;
  final String? entityId;
  final String timestamp;

  static ActivityItem fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v == null ? '' : v.toString();
    int i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    return ActivityItem(
      id: i(json['id']),
      type: s(json['type']),
      action: s(json['action']),
      user: s(json['user']),
      entityId: (json['entity_id'] as Object?)?.toString(),
      timestamp: s(json['timestamp']),
    );
  }
}

