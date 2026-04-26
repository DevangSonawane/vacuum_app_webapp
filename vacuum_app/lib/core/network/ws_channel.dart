import 'package:web_socket_channel/web_socket_channel.dart';

import 'ws_channel_io.dart' if (dart.library.html) 'ws_channel_web.dart';

/// Connects to a WebSocket endpoint and returns a [WebSocketChannel].
///
/// On IO platforms this awaits the underlying socket connection so DNS / network
/// errors are thrown here (and can be caught by callers) instead of surfacing as
/// uncaught async errors.
Future<WebSocketChannel> connectWebSocket(Uri uri) => connectWebSocketImpl(uri);
