import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> connectWebSocketImpl(Uri uri) async {
  return WebSocketChannel.connect(uri);
}
