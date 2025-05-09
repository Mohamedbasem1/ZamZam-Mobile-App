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
  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _emailController.text = 'fdsfsdf@gmail.com'; // Pre-fill the email
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _makeAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter an email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Checking user existence...';
    });

    try {
      // First check if user exists
      final userExists = await _firebaseService.checkUserExists(email);
      if (!userExists) {
        setState(() {
          _isLoading = false;
          _message = 'Error: User not found. Please make sure the user has signed up first.';
        });
        return;
      }

      setState(() {
        _message = 'Making $email an admin...';
      });

      await _firebaseService.makeUserAdminByEmail(email);
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
              // Debug section
              Divider(height: 40),
              Text('Debug Tools', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    _message = 'Listing all users...';
                  });
                  await _firebaseService.listAllUsers();
                  setState(() {
                    _message = 'Check debug console for user list';
                  });
                },
                icon: Icon(Icons.bug_report),
                label: Text('List All Users'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 