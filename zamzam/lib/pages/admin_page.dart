import 'package:flutter/material.dart';
import '../services/sync_products.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final SyncProductsService _syncService = SyncProductsService();
  bool _isLoading = false;
  String _statusMessage = '';

  // Function to show status message with loading indicator
  void _showStatus(String message) {
    setState(() {
      _statusMessage = message;
      _isLoading = true;
    });
  }

  // Function to hide loading indicator and show result
  void _hideLoading(String resultMessage) {
    setState(() {
      _statusMessage = resultMessage;
      _isLoading = false;
    });
  }

  // Function to sync all products
  Future<void> _syncAllProducts() async {
    _showStatus('Syncing all products...');
    
    try {
      await _syncService.syncProductsToFirebase();
      _hideLoading('All products synced successfully!');
    } catch (e) {
      _hideLoading('Error syncing products: $e');
    }
  }

  // Function to sync featured products
  Future<void> _syncFeaturedProducts() async {
    _showStatus('Syncing featured products...');
    
    try {
      await _syncService.syncFeaturedProductsToFirebase();
      _hideLoading('Featured products synced successfully!');
    } catch (e) {
      _hideLoading('Error syncing featured products: $e');
    }
  }

  // Function to sync products by category
  Future<void> _syncProductsByCategory(String category) async {
    _showStatus('Syncing $category products...');
    
    try {
      await _syncService.syncProductsByCategoryToFirebase(category);
      _hideLoading('$category products synced successfully!');
    } catch (e) {
      _hideLoading('Error syncing $category products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/firebase-products');
            },
            icon: Icon(Icons.view_list, color: Colors.white),
            label: Text('View Products', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Sync Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _syncAllProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Sync All Products'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _syncFeaturedProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Sync Featured Products'),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sync Products by Category:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Pens',
                        'Notebooks',
                        'Art Supplies',
                        'Ink',
                        'Montblanc',
                        'Pilot'
                      ].map((category) => ElevatedButton(
                        onPressed: _isLoading ? null : () => _syncProductsByCategory(category),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: Text(category),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
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