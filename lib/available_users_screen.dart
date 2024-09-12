import 'package:flutter/material.dart';

class AvailableUsersScreen extends StatelessWidget {
  const AvailableUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example users list
    final List<Map<String, String>> availableUsers = [
      {'username': 'User1', 'ip': '192.168.1.101'},
      {'username': 'User2', 'ip': '192.168.1.102'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Users"),
      ),
      body: ListView.builder(
        itemCount: availableUsers.length,
        itemBuilder: (context, index) {
          final user = availableUsers[index];
          return ListTile(
            title: Text(user['username'] ?? 'Unknown'),
            subtitle: Text(user['ip'] ?? 'No IP Address'),
            onTap: () {
              // Handle user selection (e.g., start chat)
            },
          );
        },
      ),
    );
  }
}
