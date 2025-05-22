import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/sync_products.dart'; // Import SyncProductsService

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final SyncProductsService _syncProductsService =
      SyncProductsService(); // Initialize SyncProductsService
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _syncStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _firebaseService.getUserData();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  Future<void> _syncProducts() async {
    setState(() {
      _isLoading = true;
      _syncStatusMessage = 'Syncing products...';
    });

    try {
      await _syncProductsService.syncProductsToFirebase();
      setState(() {
        _syncStatusMessage = 'Products synced successfully!';
      });
    } catch (e) {
      setState(() {
        _syncStatusMessage = 'Error syncing products: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _firebaseService.signOut();
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/main');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _userData?['name'] ??
                                _firebaseService.currentUser?.displayName ??
                                'User',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _userData?['email'] ??
                                _firebaseService.currentUser?.email ??
                                'Email not available',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Account Information
                  _buildSection(
                    title: 'Account Information',
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge,
                        title: 'User ID',
                        subtitle:
                            _firebaseService.currentUser?.uid ?? 'Unknown',
                      ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: 'Phone Number',
                        subtitle:
                            (_userData?['phone'] as String?)?.isNotEmpty == true
                                ? _userData!['phone']
                                : 'Not provided',
                      ),
                      _buildInfoTile(
                        icon: Icons.calendar_today,
                        title: 'Member Since',
                        subtitle: _formatTimestamp(_userData?['created_at']),
                      ),
                    ],
                  ),

                  // Account Actions
                  _buildSection(
                    title: 'Account Actions',
                    children: [
                      _buildActionTile(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit Profile coming soon')),
                          );
                        },
                      ),
                    ],
                  ),

                  // Order History
                  _buildSection(
                    title: 'My Orders',
                    children: [
                      _buildActionTile(
                        icon: Icons.shopping_bag,
                        title: 'Order History',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                              '/order-history'); // Navigate to Order History Page
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.local_shipping,
                        title: 'Track Current Order',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                              '/tracking'); // Navigate to Order Tracking Page
                        },
                      ),
                    ],
                  ),

                  // Admin Section (only visible for admin users)
                  FutureBuilder<bool>(
                    future: _checkIfAdmin(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator while checking admin status
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData && snapshot.data == true) {
                        // Show the "Admin Tools" section if the user is an admin
                        return _buildSection(
                          title: 'Admin Tools',
                          children: [
                            _buildActionTile(
                              icon: Icons.admin_panel_settings,
                              title: 'Admin Dashboard',
                              onTap: () {
                                Navigator.of(context).pushNamed('/admin');
                              },
                            ),
                            _buildActionTile(
                              icon: Icons.sync,
                              title: 'Sync Products',
                              onTap: _syncProducts, // Call the sync method
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        // Handle errors during the admin check
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error checking admin status: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      } else {
                        // If the user is not an admin, show nothing
                        return SizedBox.shrink();
                      }
                    },
                  ),

                  // Sync Status Message
                  if (_syncStatusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: _syncStatusMessage.contains('Error')
                            ? Colors.red[100]
                            : Colors.green[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _syncStatusMessage,
                            style: TextStyle(
                              color: _syncStatusMessage.contains('Error')
                                  ? Colors.red[900]
                                  : Colors.green[900],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // App Settings
                  _buildSection(
                    title: 'App Settings',
                    children: [
                      _buildActionTile(
                        icon: Icons.language,
                        title: 'Language',
                        onTap: () {
                          Navigator.of(context).pushNamed('/language');
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.help,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.of(context).pushNamed('/help');
                        },
                      ),
                    ],
                  ),

                  // Sign out button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: Icon(Icons.logout),
                      label: Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Unknown';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    if (ts is DateTime) {
      return '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}';
    }
    return ts.toString();
  }

  Future<bool> _checkIfAdmin() async {
    try {
      return await _firebaseService.isCurrentUserAdmin();
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
