import 'package:flutter/material.dart';

class LanguageSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language Settings'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to English')),
              );
            },
          ),
          ListTile(
            title: Text('Arabic'),
            trailing: Icon(Icons.check_circle_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to Arabic')),
              );
            },
          ),
          ListTile(
            title: Text('French'),
            trailing: Icon(Icons.check_circle_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to French')),
              );
            },
          ),
        ],
      ),
    );
  }
}