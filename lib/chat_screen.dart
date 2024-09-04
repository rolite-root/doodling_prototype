import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_service.dart';
import 'discovery_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class ChatScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey;

  ChatScreen({super.key})
      : _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TCPServer? _tcpServer;
  TCPClient? _tcpClient;
  UDPServer? _udpServer;
  UDPClient? _udpClient;
  final List<String> _messages = [];
  List<Map<String, String>> _discoveredDevices =
      []; // Stores device info with IP and Username
  String? _selectedDevice;
  String? _selectedUsername;
  final TextEditingController _messageController = TextEditingController();
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _setupServer();
    _discoverDevices();
    _recorder = FlutterSoundRecorder();
  }

  Future<void> _setupServer() async {
    _tcpServer = TCPServer();
    await _tcpServer?.startServer(8080, _onMessageReceived);
    _udpServer = UDPServer();
    await _udpServer?.startServer(8081, _onMessageReceived);
  }

  Future<void> _discoverDevices() async {
    DiscoveryService discoveryService = DiscoveryService();
    List<Map<String, String>> discoveredDevices =
        await discoveryService.discoverDevices();

    setState(() {
      _discoveredDevices = discoveredDevices;
    });
  }

  void _onMessageReceived(String message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _connectToDevice(String deviceIP, String username) async {
    _tcpClient = TCPClient();
    await _tcpClient?.connectToServer(deviceIP, 8080, _onMessageReceived);
    setState(() {
      _selectedDevice = deviceIP;
      _selectedUsername = username;
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

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      // Logic to send the file goes here.
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecording) {
      await _recorder?.openRecorder();
      await _recorder?.startRecorder(toFile: 'audio_message.aac');
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      String? path = await _recorder?.stopRecorder();
      await _recorder?.closeRecorder();
      setState(() {
        _isRecording = false;
      });
      // Logic to send the recorded audio file goes here.
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Navigate to login screen
  }

  Future<void> _switchAccount() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Navigate to login screen
  }

  void _showAvailableUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AvailableUsersScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tcpServer?.stopServer();
    _udpServer?.stopServer();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Chat"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text("Options")),
            ListTile(
              title: const Text("Logout"),
              onTap: () async {
                await _logout();
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              title: const Text("Switch Account"),
              onTap: () async {
                await _switchAccount();
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              title: const Text("Available Users"),
              onTap: () {
                _showAvailableUsers();
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
          ],
        ),
      ),
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
          final device = _discoveredDevices[index];
          return ListTile(
            title: Text(device['username']!),
            onTap: () => _connectToDevice(device['ip']!, device['username']!),
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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _sendFile,
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class AvailableUsersScreen extends StatefulWidget {
  const AvailableUsersScreen({super.key});

  @override
  _AvailableUsersScreenState createState() => _AvailableUsersScreenState();
}

class _AvailableUsersScreenState extends State<AvailableUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableUsers();
  }

  Future<void> _fetchAvailableUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs
          .map((doc) => {'id': doc.id, 'username': doc['username']})
          .toList();
      setState(() {
        _availableUsers = users;
      });
    } catch (e) {
      print('Error fetching available users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Users"),
      ),
      body: ListView.builder(
        itemCount: _availableUsers.length,
        itemBuilder: (context, index) {
          final user = _availableUsers[index];
          return ListTile(
            title: Text(user['username']),
            onTap: () {
              // Start a chat with the selected user or perform other actions
              Navigator.of(context).pop(); // Go back to the previous screen
              // Add your chat initiation code here
            },
          );
        },
      ),
    );
  }
}
