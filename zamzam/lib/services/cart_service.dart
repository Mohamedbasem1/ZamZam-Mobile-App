import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/api_services.dart' show Product;

class CartItem {
  final String productId;
  final String name;
  final String price;
  final String image;
  final String url;
  final double rating;
  final int ratingCount;
  final bool isFeatured;
  final int id;
  final int stockCount;
  int quantity;
  final DateTime? addedAt;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.url,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFeatured = false,
    this.id = 0,
    this.stockCount = 0,
    this.quantity = 1,
    this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'image': image,
      'url': url,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFeatured': isFeatured,
      'id': id,
      'stockCount': stockCount,
      'quantity': quantity,
      'addedAt': addedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      image: map['image'] ?? '',
      url: map['url'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      id: map['id'] ?? 0,
      stockCount: map['stockCount'] ?? 0,
      quantity: map['quantity'] ?? 1,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      image: image,
      url: url,
      rating: rating,
      ratingCount: ratingCount,
      isFeatured: isFeatured,
      id: id,
      stockCount: stockCount,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt,
    );
  }
}

class CartService {
  static final CartService _instance = CartService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final _cartController = StreamController<List<CartItem>>.broadcast();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  // Stream getter
  Stream<List<CartItem>> get cartStream => _cartController.stream;

  // Get cart count
  Future<int> getCartCount() async {
    try {
      if (!_firebaseService.isLoggedIn) return 0;

      String userId = _firebaseService.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('cart')
          .doc(userId)
          .collection('cart_items')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Clear local cart
  void clearLocalCart() {
    _safeAddToStream([]);
  }

  // Safely add items to the stream controller
  void _safeAddToStream(List<CartItem> items) {
    if (!_cartController.isClosed) {
      _cartController.add(items);
    }
  }

  // Dispose
  void dispose() {
    if (!_cartController.isClosed) {
      _cartController.close();
    }
  }

  // Helper method to parse price string
  double _parsePrice(String price) {
    try {
      // Remove 'EGP' and any other non-numeric characters except decimal point
      String cleanPrice =
          price.replaceAll('EGP', '').replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(cleanPrice);
    } catch (e) {
      print('Error parsing price: $e');
      return 0.0;
    }
  }

  // Add or update cart item
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to manage cart');
      }

      // Validate product data
      if (product.url.isEmpty) {
        throw Exception('Invalid product data: URL is required');
      }

      String userId = _firebaseService.currentUser!.uid;
      String productId =
          product.docId ?? product.url.replaceAll(RegExp(r'[^\w\s-]'), '_');

      try {
        // Reference to the user's cart document
        DocumentReference cartRef = _firestore
            .collection('cart')
            .doc(userId)
            .collection('cart_items')
            .doc(productId);

        // Check if the item is already in cart
        DocumentSnapshot doc = await cartRef.get();

        if (doc.exists) {
          // Update quantity
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int currentQuantity = data['quantity'] ?? 0;
          await cartRef.update({'quantity': currentQuantity + quantity});
        } else {
          // Validate required product data
          if (product.name.isEmpty) {
            throw Exception('Invalid product data: Name is required');
          }

          // Format the price
          double priceValue = _parsePrice(product.price);
          String formattedPrice = priceValue.toStringAsFixed(2);

          // Add new item to cart
          CartItem cartItem = CartItem(
            productId: productId,
            name: product.name,
            price: formattedPrice,
            image: product.image,
            url: product.url,
            rating: product.rating,
            ratingCount: product.ratingCount,
            isFeatured: product.isFeatured,
            id: product.id,
            stockCount: product.stockCount,
            quantity: quantity,
          );

          await cartRef.set(cartItem.toMap());
        }

        // Update the stream with new cart items
        List<CartItem> updatedItems = await _getCartItemsList();
        _safeAddToStream(updatedItems);
      } catch (firestoreError) {
        print('Firestore operation error: $firestoreError');
        throw Exception('Failed to update cart in database: $firestoreError');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      throw Exception('Failed to update cart: ${e.toString()}');
    }
  }

  // Helper method to get cart items list
  Future<List<CartItem>> _getCartItemsList() async {
    if (!_firebaseService.isLoggedIn) return [];

    String userId = _firebaseService.currentUser!.uid;
    QuerySnapshot snapshot = await _firestore
        .collection('cart')
        .doc(userId)
        .collection('cart_items')
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return CartItem.fromMap(data);
    }).toList();
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to manage cart');
      }

      String userId = _firebaseService.currentUser!.uid;
      DocumentReference cartRef = _firestore
          .collection('cart')
          .doc(userId)
          .collection('cart_items')
          .doc(productId);

      if (quantity <= 0) {
        await cartRef.delete();
      } else {
        await cartRef.update({'quantity': quantity});
      }

      // Update the stream
      List<CartItem> updatedItems = await _getCartItemsList();
      _safeAddToStream(updatedItems);
    } catch (e) {
      print('Error updating quantity: $e');
      throw Exception('Failed to update quantity: ${e.toString()}');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to manage cart');
      }

      String userId = _firebaseService.currentUser!.uid;
      await _firestore
          .collection('cart')
          .doc(userId)
          .collection('cart_items')
          .doc(productId)
          .delete();

      // Update the stream
      List<CartItem> updatedItems = await _getCartItemsList();
      _safeAddToStream(updatedItems);
    } catch (e) {
      print('Error removing from cart: $e');
      throw Exception('Failed to remove item from cart: ${e.toString()}');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to manage cart');
      }

      String userId = _firebaseService.currentUser!.uid;
      QuerySnapshot cartItems = await _firestore
          .collection('cart')
          .doc(userId)
          .collection('cart_items')
          .get();

      WriteBatch batch = _firestore.batch();
      cartItems.docs.forEach((doc) {
        batch.delete(doc.reference);
      });

      await batch.commit();

      // Update the stream safely
      _safeAddToStream([]);
    } catch (e) {
      print('Error clearing cart: $e');
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  // Get cart items stream
  Stream<List<CartItem>> getCartItemsStream() {
    if (!_firebaseService.isLoggedIn) {
      return Stream.value([]);
    }

    String userId = _firebaseService.currentUser!.uid;
    return _firestore
        .collection('cart')
        .doc(userId)
        .collection('cart_items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return CartItem.fromMap(data);
      }).toList();
    });
  }

  // Calculate cart total
  Future<double> getCartTotal() async {
    try {
      if (!_firebaseService.isLoggedIn) return 0.0;

      String userId = _firebaseService.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('cart')
          .doc(userId)
          .collection('cart_items')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double price = double.tryParse(data['price'].toString()) ?? 0.0;
        int quantity = data['quantity'] ?? 1;
        total += price * quantity;
      }
      return total;
    } catch (e) {
      print('Error calculating cart total: $e');
      return 0.0;
    }
  }
}
