import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteProductPage extends StatefulWidget {
  @override
  _DeleteProductPageState createState() => _DeleteProductPageState();
}

class _DeleteProductPageState extends State<DeleteProductPage> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Product'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products found.'));
                }
                final products = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchText);
                }).toList();

                if (products.isEmpty) {
                  return Center(child: Text('No products match your search.'));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product['name'] ?? ''),
                      subtitle: Text('Price: \$${product['price'] ?? ''}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Product'),
                              content: Text('Are you sure you want to delete this product?'),
                              actions: [
                                TextButton(
                                  child: Text('No'),
                                  onPressed: () => Navigator.of(context).pop(false),
                                ),
                                TextButton(
                                  child: Text('Yes'),
                                  onPressed: () => Navigator.of(context).pop(true),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('Products')
                                .doc(product['docId'])
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Product deleted')),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}