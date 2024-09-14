import 'package:flutter/material.dart';
import 'chat_with_user_screen.dart';

class AvailableUsersScreen extends StatelessWidget {
  final List<Map<String, String>> availableUsers;

  const AvailableUsersScreen({super.key, required this.availableUsers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Users"),
      ),
      body: availableUsers.isEmpty
          ? const Center(child: Text("No users available"))
          : ListView.builder(
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                return ListTile(
                  title: Text(user['username'] ?? 'Unknown'),
                  subtitle: Text(user['ip'] ?? 'No IP Address'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatWithUserScreen(
                          username: user['username']!,
                          ipAddress: user['ip']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
