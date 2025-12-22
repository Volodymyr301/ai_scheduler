import 'dart:async';

import 'package:web_socket_client/web_socket_client.dart';

class CustomWebSocketClient {
  final _uri = Uri.parse('ws://188.36.211.190:25779');

  /// Trigger a timeout if establishing a connection exceeds 10s.
  final _timeout = Duration(seconds: 10);

  final _backoff = LinearBackoff(
    initial: const Duration(seconds: 0),
    increment: const Duration(seconds: 1),
    maximum: const Duration(seconds: 5),
  );

  WebSocket? _socket;

  /// Open connection
  void openConnection() {
    // Create a WebSocket client.
    _socket = WebSocket(_uri, backoff: _backoff, timeout: _timeout);
  }

  /// Send a message to the server.
  void sendMessage(dynamic data) {
    _socket?.send(data);
  }

  /// Listen for incoming messages.
  Stream<dynamic>? get stream {
    return _socket?.messages;
  }

  /// Close the connection.
  void closeConnection() {
    _socket?.close();
  }
}
