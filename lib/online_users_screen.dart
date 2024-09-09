import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class OnlineUsersScreen extends StatelessWidget {
  const OnlineUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Users')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<AuthService>(context).getOnlineUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading users'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users online'));
          }

          List<Map<String, dynamic>> onlineUsers = snapshot.data!;

          return ListView.builder(
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(onlineUsers[index]['email']),
              );
            },
          );
        },
      ),
    );
  }
}
