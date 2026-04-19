import '../domain/app_notification.dart';

class NotificationsState {
  const NotificationsState({
    required this.items,
    required this.unreadCount,
    required this.connected,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool connected;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? connected,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      connected: connected ?? this.connected,
    );
  }

  static const empty = NotificationsState(items: [], unreadCount: 0, connected: false);
}

