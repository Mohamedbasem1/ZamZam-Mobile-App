import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'make_admin_page.dart';
import 'list_users_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orders Management Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin/orders');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Update Orders',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // User Management Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MakeAdminPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Make Admin',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ListUsersPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'View All Users',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                        // Products Control Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/add_product');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: Text('Add'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/delete_product');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            textStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: Text('Delete'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/update_product');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            textStyle: TextStyle(color: Colors.white),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Status Message
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(_statusMessage),
                  ],
                ),
              )
            else if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('Error') ? Colors.red[100] : Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error') ? Colors.red[900] : Colors.green[900],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}