import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'available_users_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = true; // Track if the UI is ready
  User? _user; // Store the Firebase user

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeRecorder();
    await _initializeNotifications();
    await _loadUserData();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    // Simulate data loading delay (e.g., from a database or network)
    await Future.delayed(const Duration(seconds: 2)); // Example delay
    setState(() {
      _isLoading = false; // UI is ready to be interacted with
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'message_channel', // Channel ID
      'Message Notifications', // Channel name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      print('Sending message: $message');
      _messageController.clear();
      _showNotification("New Message Sent", message);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      print('Sending file: ${file.path}');
      _showNotification("File Sent", "You have sent a file.");
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
    });
    await _recorder.startRecorder(toFile: 'audio_message.aac');
  }

  Future<void> _stopRecording() async {
    String? audioPath = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (audioPath != null) {
      print('Sending audio: $audioPath');
      _showNotification(
          "Audio Message Sent", "You have sent an audio message.");
    }
  }

  Widget _buildMessageInput() {
    return Expanded(
      child: TextField(
        controller: _messageController,
        decoration: const InputDecoration(
          hintText: 'Enter your message...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAudioInput() {
    return IconButton(
      icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
      onPressed: _isLoading
          ? null
          : (_isRecording
              ? _stopRecording
              : _startRecording), // Disable when loading
    );
  }

  void _showAvailableUsers() {
    if (!_isLoading) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AvailableUsersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: const Text("Chat"),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    if (!_isLoading) {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: _showAvailableUsers,
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(_user?.displayName ?? 'Guest User'),
                      accountEmail: Text(_user?.email ?? 'No Email'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text("Profile"),
                      onTap: () {
                        if (!_isLoading) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()));
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings"),
                      onTap: () {
                        if (!_isLoading) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsScreen()));
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Help & Support"),
                      onTap: () {
                        if (!_isLoading) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen()));
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Logout"),
                      onTap: () async {
                        if (!_isLoading) {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(children: const []),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildMessageInput(),
                      _buildAudioInput(),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
