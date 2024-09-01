import 'dart:io';
import 'package:flutter/material.dart';
import 'tcp_client.dart';
import 'tcp_server.dart';
import 'udp_client.dart';
import 'udp_server.dart';
import 'discovery_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TCPServer? _tcpServer;
  TCPClient? _tcpClient;
  UDPServer? _udpServer;
  UDPClient? _udpClient;
  List<String> _messages = [];
  List<String> _discoveredDevices = [];
  String? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _setupServer();
    _discoverDevices();
  }

  Future<void> _setupServer() async {
    _tcpServer = TCPServer();
    await _tcpServer?.startServer(8080, _onMessageReceived);
    _udpServer = UDPServer();
    await _udpServer?.startServer(8081, _onMessageReceived);
  }

  Future<void> _discoverDevices() async {
    DiscoveryService discoveryService = DiscoveryService();
    List<String> devices = await discoveryService.discoverDevices();
    setState(() {
      _discoveredDevices = devices;
    });
  }

  void _onMessageReceived(String message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _connectToDevice(String deviceIP) async {
    _tcpClient = TCPClient();
    await _tcpClient?.connectToServer(deviceIP, 8080, _onMessageReceived);
    setState(() {
      _selectedDevice = deviceIP;
    });
  }

  void _sendMessage(String message) {
    if (_tcpClient != null) {
      _tcpClient?.sendMessage(message);
    } else if (_udpClient != null && _selectedDevice != null) {
      _udpClient?.sendMessage(
        InternetAddress(_selectedDevice!), // Correct usage of InternetAddress
        8081,
        message,
      );
    }
    setState(() {
      _messages.add("Me: $message");
    });
  }

  @override
  void dispose() {
    _tcpServer?.stopServer();
    _udpServer?.stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          if (_selectedDevice == null)
            Expanded(
              child: ListView.builder(
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_discoveredDevices[index]),
                    onTap: () => _connectToDevice(_discoveredDevices[index]),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(_messages[index])),
              ),
            ),
          if (_selectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(onSubmitted: _sendMessage)),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage('Test message'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
