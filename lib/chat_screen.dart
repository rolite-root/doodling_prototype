import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_service.dart';
import 'discovery_service.dart';
import 'device_responder.dart';  
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_auth/firebase_auth.dart';



class ChatScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey;

  ChatScreen({super.key}) : _scaffoldKey = GlobalKey<ScaffoldState>();

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
  List<Map<String, String>> _discoveredDevices =[]; // Stores device info with IP and Username
  String? _selectedDevice;
  String? _selectedUsername;
  final TextEditingController _messageController = TextEditingController();
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _setupServer();
    _startDeviceResponder();
    _discoverDevices();
    _recorder = FlutterSoundRecorder();
  }

  Future<void> _setupServer() async {
    _tcpServer = TCPServer();
    await _tcpServer?.startServer(8080, _onMessageReceived);
    _udpServer = UDPServer();
    await _udpServer?.startServer(8081, _onMessageReceived);
  }


  Future<void> _startDeviceResponder() async {
    DeviceResponder responder = const DeviceResponder();
    await responder.startResponder();  // Start the device responder to advertise the device
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
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                'Hello, ${FirebaseAuth.instance.currentUser?.email}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await _logout();
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text("Switch Account"),
              onTap: () async {
                await _switchAccount();
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
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
          bool isConnected = device['ip'] == _selectedDevice;

          return ListTile(
            title: Text(
              device['username'] ?? 'Unknown',
              style: TextStyle(color: isConnected ? Colors.black : Colors.grey),
            ),
            leading: Icon(
              isConnected ? Icons.lock_open : Icons.lock,
              color: isConnected ? Colors.black : Colors.grey,
            ),
            onTap: () {
              if (!isConnected) {
                _connectToDevice(device['ip']!, device['username']!);
              }
            },
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

// Settings Screen for changing username
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration:
                  const InputDecoration(labelText: 'Enter New Username'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      String newUsername = _usernameController.text.trim();
                      bool usernameExists =
                          await _checkUsernameExists(newUsername);

                      if (usernameExists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username already exists.')),
                        );
                      } else {
                        await _updateUsername(newUsername);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Username updated successfully.')),
                        );
                      }

                      setState(() {
                        _isLoading = false;
                      });
                    },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Username'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUsernameExists(String username) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _updateUsername(String newUsername) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': newUsername,
    });
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
              Navigator.of(context).pop(); // Go back to the previous screen
              // Add your chat initiation code here
            },
          );
        },
      ),
    );
  }
}
