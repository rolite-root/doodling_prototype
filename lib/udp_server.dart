import 'dart:io';

class UDPServer {
  RawDatagramSocket? _udpSocket;

  Future<void> startServer(int port, Function(String) onMessageReceived) async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _udpSocket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _udpSocket?.receive();
        if (datagram != null) {
          final message = String.fromCharCodes(datagram.data);
          onMessageReceived(message);
        }
      }
    });
  }

  void sendMessage(InternetAddress address, int port, String message) {
    _udpSocket?.send(message.codeUnits, address, port);
  }

  void stopServer() {
    _udpSocket?.close();
    _udpSocket = null;
  }
}
