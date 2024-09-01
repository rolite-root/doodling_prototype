import 'dart:io';

class UDPClient {
  RawDatagramSocket? _udpSocket;

  Future<void> connectToServer(int port) async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  }

  void sendMessage(InternetAddress address, int port, String message) {
    _udpSocket?.send(message.codeUnits, address, port);
  }

  void listenForMessages(Function(String) onMessageReceived) {
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

  void disconnect() {
    _udpSocket?.close();
    _udpSocket = null;
  }
}
