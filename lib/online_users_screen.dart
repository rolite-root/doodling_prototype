import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class OnlineUsersScreen extends StatelessWidget {
  const OnlineUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> onlineUsers = Provider.of<AuthService>(context).getOnlineUsers();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Users')),
      body: ListView.builder(
        itemCount: onlineUsers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(onlineUsers[index]),
          );
        },
      ),
    );
  }
}
