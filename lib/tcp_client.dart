import 'dart:io';
import 'dart:convert';

class TCPClient {
  Socket? _socket;

  Future<void> connectToServer(String host, int port, Function(String) onMessageReceived) async {
    _socket = await Socket.connect(host, port);
    _socket?.listen((List<int> data) {
      final message = utf8.decode(data);
      onMessageReceived(message);
    });
  }

  void sendMessage(String message) {
    _socket?.write(message);
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
  }
}
