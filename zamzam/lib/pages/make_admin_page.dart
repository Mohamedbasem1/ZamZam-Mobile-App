import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class MakeAdminPage extends StatefulWidget {
  const MakeAdminPage({Key? key}) : super(key: key);

  @override
  _MakeAdminPageState createState() => _MakeAdminPageState();
}

class _MakeAdminPageState extends State<MakeAdminPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _makeAdmin() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || name.isEmpty) {
      setState(() {
        _message = 'Please enter both email and name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Updating user to admin status...';
    });

    try {
      // Use the FirebaseService function to update the user to admin
      await _firebaseService.updateUserToAdmin(email, name);

      setState(() {
        _message = 'Successfully made $email an admin!';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Admin'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
                enabled: !_isLoading,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _makeAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text('Make Admin'),
                ),
              SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('Error') ? Colors.red : Colors.green,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}