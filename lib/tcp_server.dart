import 'dart:io';
import 'dart:convert';

class TCPServer {
  ServerSocket? _serverSocket;

  Future<void> startServer(int port, Function(String) onMessageReceived) async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket?.listen((Socket client) {
      client.listen((List<int> data) {
        final message = utf8.decode(data);
        onMessageReceived(message);
      });
    });
  }

  void stopServer() {
    _serverSocket?.close();
    _serverSocket = null;
  }

  void sendMessage(Socket client, String message) {
    client.write(message);
  }
}
