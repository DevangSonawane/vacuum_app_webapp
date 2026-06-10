import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/ws_channel.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import 'notifications_state.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(dio: ref.read(dioProvider));
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  static const _wsUrl = 'wss://vaccumapi.onrender.com/ws';
  static const _supportedEvents = {
    'job_raised',
    'job_status',
    'report_submitted',
    'report_reviewed',
    'amc_expiring',
    'amc_created',
    'notification',
  };

  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _activeToken;

  @override
  Future<NotificationsState> build() async {
    ref.onDispose(_disconnect);

    final auth = ref.watch(authProvider).valueOrNull;
    final isAuthed = auth?.isAuthenticated ?? false;
    final token = await ref.read(tokenStorageProvider).readToken();
    if (!isAuthed || token == null || token.isEmpty) {
      _disconnect();
      _activeToken = null;
      return NotificationsState.empty;
    }

    if (_activeToken != token) {
      _disconnect();
      _activeToken = token;
    }

    unawaited(_connect(token));
    try {
      final result = await _repo.fetch(limit: 30);
      return NotificationsState(
        items: result.items,
        unreadCount: result.unreadCount,
        connected: false,
      );
    } catch (_) {
      return const NotificationsState(
        items: [],
        unreadCount: 0,
        connected: false,
      );
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? NotificationsState.empty;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetch(limit: 30);
      return current.copyWith(
        items: result.items,
        unreadCount: result.unreadCount,
      );
    });
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? NotificationsState.empty;
    state = AsyncData(
      current.copyWith(
        items: [for (final n in current.items) n.copyWith(read: true)],
        unreadCount: 0,
      ),
    );
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  Future<void> markRead(AppNotification n) async {
    final current = state.valueOrNull ?? NotificationsState.empty;
    if (n.read) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final it in current.items)
            if (it.id == n.id) it.copyWith(read: true) else it,
        ],
        unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
      ),
    );
    final serverId = n.serverId;
    if (serverId == null) return;
    try {
      await _repo.markRead([serverId]);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final current = state.valueOrNull ?? NotificationsState.empty;
    state = AsyncData(current.copyWith(items: const [], unreadCount: 0));
    try {
      await _repo.clearAll();
    } catch (_) {}
  }

  Future<void> _connect(String token) async {
    if (_channel != null && _activeToken == token) return;
    if (_channel != null) {
      _disconnect(keepConnectedFlag: true);
    }

    try {
      _channel = await connectWebSocket(Uri.parse(_wsUrl));
      try {
        _channel!.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      } catch (_) {}

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });

      _sub?.cancel();
      _sub = _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (_) => _scheduleReconnect(token),
        onDone: () => _scheduleReconnect(token),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect(token);
    }
  }

  void _handleMessage(Object? raw) {
    final text = raw?.toString() ?? '';
    if (text.isEmpty) return;

    Map<String, dynamic> msg;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return;
      msg = decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      return;
    }

    final event = (msg['event'] ?? '').toString();
    if (event == 'pong' || event == 'connected') {
      if (event == 'connected') {
        final current = state.valueOrNull ?? NotificationsState.empty;
        state = AsyncData(current.copyWith(connected: true));
      }
      return;
    }

    if (event.isEmpty || !_supportedEvents.contains(event)) {
      return;
    }

    final current = state.valueOrNull ?? NotificationsState.empty;

    final meta = notificationMeta(event);
    final data = _asMap(msg['data']);
    final title = (data['title'] ?? '').toString().trim();
    final message = (data['message'] ?? '').toString().trim();
    final entityType = (data['entity_type'] as Object?)?.toString();
    final entityId = (data['entity_id'] as Object?)?.toString();
    final tsRaw = (msg['ts'] ?? '').toString();
    final ts = _parseTime(tsRaw) ?? DateTime.now();

    final item = AppNotification(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      serverId: null,
      event: event,
      title: title.isNotEmpty ? title : meta.title,
      message: message.isNotEmpty
          ? message
          : formatNotificationMessage(event, data),
      entityType: entityType,
      entityId: entityId,
      timestamp: ts,
      read: false,
      fromDb: false,
    );

    final nextItems = [item, ...current.items].take(50).toList();
    state = AsyncData(
      current.copyWith(items: nextItems, unreadCount: current.unreadCount + 1),
    );
  }

  void _scheduleReconnect(String token) {
    _disconnect(keepConnectedFlag: true);
    final current = state.valueOrNull ?? NotificationsState.empty;
    state = AsyncData(current.copyWith(connected: false));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () async {
      final auth = ref.read(authProvider).valueOrNull;
      final isAuthed = auth?.isAuthenticated ?? false;
      final fresh = await ref.read(tokenStorageProvider).readToken();
      if (!isAuthed || fresh == null || fresh.isEmpty) return;
      unawaited(_connect(fresh));
    });
  }

  void _disconnect({bool keepConnectedFlag = false}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    if (!keepConnectedFlag) {
      _activeToken = null;
    }

    if (!keepConnectedFlag) {
      final current = state.valueOrNull ?? NotificationsState.empty;
      if (current.connected) {
        state = AsyncData(current.copyWith(connected: false));
      }
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  static DateTime? _parseTime(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }
}
