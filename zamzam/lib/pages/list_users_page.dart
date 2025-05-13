import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ListUsersPage extends StatefulWidget {
  const ListUsersPage({Key? key}) : super(key: key);

  @override
  _ListUsersPageState createState() => _ListUsersPageState();
}

class _ListUsersPageState extends State<ListUsersPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch all users using the FirebaseService
      final querySnapshot = await _firebaseService.listAllUsers();
      final users = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching users: $e';
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
        title: Text('List of Users'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(user['name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user['email'] ?? 'No Email'}'),
                          ],
                        ),
                        trailing: Icon(Icons.person),
                      ),
                    );
                  },
                ),
    );
  }
}