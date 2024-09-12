import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Help & Support",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Contact Support"),
              onTap: () {
                // Handle contact support action
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("User Guide"),
              onTap: () {
                // Handle viewing user guide
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text("FAQs"),
              onTap: () {
                // Handle viewing FAQs
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
