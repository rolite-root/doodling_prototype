import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_service.dart';
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
  final TextEditingController _messageController = TextEditingController();

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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      if (_tcpClient != null) {
        _tcpClient?.sendMessage(message);
      } else if (_udpClient != null && _selectedDevice != null) {
        _udpClient?.sendMessage(
          InternetAddress(_selectedDevice!),
          8081,
          message,
        );
      }
      setState(() {
        _messages.add("Me: $message");
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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
          _selectedDevice == null ? _buildDeviceList() : _buildMessageList(),
          if (_selectedDevice != null) _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _discoveredDevices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_discoveredDevices[index]),
            onTap: () => _connectToDevice(_discoveredDevices[index]),
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) =>
            ListTile(title: Text(_messages[index])),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
