import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/firebase_service.dart';
import '../services/api_services.dart';
import 'dart:convert';
import 'dart:typed_data';

class BrowseProductsPage extends StatefulWidget {
  @override
  _BrowseProductsPageState createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  String _searchText = '';
  String _selectedCategory = 'All';
  final CartService _cartService = CartService();
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browse Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                _buildCategoryChip('All', true),
                _buildCategoryChip('Pens', false),
                _buildCategoryChip('Notebooks', false),
                _buildCategoryChip('Art Supplies', false),
              ],
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
                  final matchesSearch = name.contains(_searchText);
                  
                  // Filter by category if not "All"
                  if (_selectedCategory != 'All') {
                    final productCategory = (doc['category'] ?? '').toString();
                    return matchesSearch && productCategory == _selectedCategory;
                  }
                  
                  return matchesSearch;
                }).toList();

                if (products.isEmpty) {
                  return Center(child: Text('No products match your search.'));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    
                    // Decode base64 image if available
                    Uint8List? imageBytes;
                    if (product['image'] != null && product['image'] != '') {
                      try {
                        imageBytes = base64Decode(product['image']);
                      } catch (_) {}
                    }
                    
                    return Card(
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              child: imageBytes != null
                                ? Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                          // Product Details
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'Unnamed Product',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'EGP ${product['price'] ?? '0.0'}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Add to Cart Button
                                    IconButton(
                                      icon: Icon(Icons.add_shopping_cart, color: Colors.blue),
                                      onPressed: () async {
                                        try {
                                          // Convert to Product object
                                          final productObj = Product(
                                            name: product['name'] ?? '',
                                            price: 'EGP ${product['price'] ?? '0.0'}',
                                            image: product['image'] ?? '',
                                            url: product['url'] ?? '',
                                            nameUrl: product['nameUrl'] ?? '',
                                            rating: (product['rating'] ?? 0.0).toDouble(),
                                            ratingCount: (product['ratingCount'] ?? 0),
                                            isFeatured: product['isFeatured'] ?? false,
                                            docId: product['docId'] ?? product.id,
                                            id: product['id'] ?? 0,
                                            stockCount: product['stockCount'] ?? 0,
                                          );
                                          
                                          await _cartService.addToCart(productObj);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Added to cart')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                    ),
                                    // Favorite Button
                                    IconButton(
                                      icon: Icon(Icons.favorite_border, color: Colors.red),
                                      onPressed: () async {
                                        try {
                                          // Convert to Product object
                                          final productObj = Product(
                                            name: product['name'] ?? '',
                                            price: 'EGP ${product['price'] ?? '0.0'}',
                                            image: product['image'] ?? '',
                                            url: product['url'] ?? '',
                                            nameUrl: product['nameUrl'] ?? '',
                                            rating: (product['rating'] ?? 0.0).toDouble(),
                                            ratingCount: (product['ratingCount'] ?? 0),
                                            isFeatured: product['isFeatured'] ?? false,
                                            docId: product['docId'] ?? product.id,
                                            id: product['id'] ?? 0,
                                            stockCount: product['stockCount'] ?? 0,
                                          );
                                          
                                          await _favoriteService.toggleFavorite(productObj);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Added to favorites')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(category),
        selected: _selectedCategory == category,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }
}