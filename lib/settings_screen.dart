import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () {
                // Handle notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Security"),
              onTap: () {
                // Handle security settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy"),
              onTap: () {
                // Handle privacy settings
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
