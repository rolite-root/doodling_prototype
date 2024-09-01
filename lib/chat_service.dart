import 'dart:io';

class TCPServer {
  ServerSocket? _serverSocket;

  Future<void> startServer(int port, Function(String) onMessageReceived) async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket?.listen((Socket client) {
      client.listen((List<int> data) {
        String message = String.fromCharCodes(data);
        onMessageReceived(message);
      });
    });
  }

  void stopServer() {
    _serverSocket?.close();
  }
}

class TCPClient {
  Socket? _socket;

  Future<void> connectToServer(
      String ip, int port, Function(String) onMessageReceived) async {
    _socket = await Socket.connect(ip, port);
    _socket?.listen((List<int> data) {
      String message = String.fromCharCodes(data);
      onMessageReceived(message);
    });
  }

  void sendMessage(String message) {
    _socket?.write(message);
  }

  void disconnect() {
    _socket?.destroy();
  }
}

class UDPServer {
  RawDatagramSocket? _udpSocket;

  Future<void> startServer(int port, Function(String) onMessageReceived) async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _udpSocket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _udpSocket?.receive();
        if (dg != null) {
          String message = String.fromCharCodes(dg.data);
          onMessageReceived(message);
        }
      }
    });
  }

  void stopServer() {
    _udpSocket?.close();
  }
}

class UDPClient {
  void sendMessage(InternetAddress ipAddress, int port, String message) {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      socket.send(message.codeUnits, ipAddress, port);
      socket.close();
    });
  }
}
