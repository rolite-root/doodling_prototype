import 'package:flutter/material.dart';

class ChatWithUserScreen extends StatelessWidget {
  final String username;
  final String ipAddress;

  const ChatWithUserScreen({
    super.key,
    required this.username,
    required this.ipAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with $username"),
      ),
      body: Center(
        child: Text("Chat functionality for $username ($ipAddress)"),
      ),
    );
  }
}
