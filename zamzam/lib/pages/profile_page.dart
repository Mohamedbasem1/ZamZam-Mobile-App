import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

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

  Future<void> _signOut() async {
    await _firebaseService.signOut();
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        // Replace the default back button with a custom one that navigates to main page
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
                          // Profile Avatar
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

                          // User Name
                          Text(
                            _userData?['name'] ??
                                _firebaseService.currentUser?.displayName ??
                                'User',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // User Email
                          Text(
                            _userData?['email'] ??
                                _firebaseService.currentUser?.email ??
                                'Email not available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
                          // TODO: Navigate to edit profile page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit Profile coming soon')),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.location_on,
                        title: 'Manage Addresses',
                        onTap: () {
                          // TODO: Navigate to addresses page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Manage Addresses coming soon')),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: () {
                          // TODO: Navigate to change password page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Change Password coming soon')),
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
                          // TODO: Navigate to order history page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Order History coming soon')),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.local_shipping,
                        title: 'Track Current Order',
                        onTap: () {
                          // TODO: Navigate to order tracking page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Order Tracking coming soon')),
                          );
                        },
                      ),
                    ],
                  ),

                  // App Settings
                  _buildSection(
                    title: 'App Settings',
                    children: [
                      _buildActionTile(
                        icon: Icons.notifications,
                        title: 'Notification Preferences',
                        onTap: () {
                          // TODO: Navigate to notifications settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Notification Settings coming soon')),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.language,
                        title: 'Language',
                        onTap: () {
                          // TODO: Navigate to language settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Language Settings coming soon')),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.help,
                        title: 'Help & Support',
                        onTap: () {
                          // TODO: Navigate to help center
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Help & Support coming soon')),
                          );
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
}
