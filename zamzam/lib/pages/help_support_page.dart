import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('How do I track my order?'),
              subtitle: Text('Go to the "Track Current Order" section in your profile.'),
            ),
            ListTile(
              title: Text('How do I contact support?'),
              subtitle: Text('You can email us at support@zamzam.com.'),
            ),
            ListTile(
              title: Text('How do I change my language settings?'),
              subtitle: Text('Go to the "Language Settings" section in your profile.'),
            ),
            SizedBox(height: 24),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email, color: Colors.indigo),
              title: Text('Email'),
              subtitle: Text('support@zamzam.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.indigo),
              title: Text('Phone'),
              subtitle: Text('+1 234 567 890'),
            ),
          ],
        ),
      ),
    );
  }
}