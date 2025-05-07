import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/api_services.dart';

class CartItem {
  final String productId;
  final String name;
  final String price;
  final String image;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      name: map['name'],
      price: map['price'],
      image: map['image'],
      quantity: map['quantity'],
    );
  }
}

class CartService {
  static final CartService _instance = CartService._internal();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cart for guest mode and stream for real-time updates
  List<CartItem> _localCart = [];
  final _cartController = StreamController<List<CartItem>>.broadcast();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  Stream<List<CartItem>> get cartStream => _cartController.stream;

  // Get cart count
  Future<int> getCartCount() async {
    if (!_firebaseService.isLoggedIn) {
      return _localCart.length;
    }

    try {
      String userId = _firebaseService.currentUser!.uid;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('cart_items')
          .get();

      if (doc.exists) {
        List<dynamic> items = doc.get('items') ?? [];
        return items.length;
      }
      return 0;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Add to cart
  Future<void> addToCart(Product product) async {
    final item = CartItem(
      productId: product.url,
      name: product.name,
      price: product.price,
      image: product.image,
    );

    if (!_firebaseService.isLoggedIn) {
      // Guest mode - use local cart
      int existingIndex =
          _localCart.indexWhere((i) => i.productId == item.productId);
      if (existingIndex >= 0) {
        _localCart[existingIndex].quantity++;
      } else {
        _localCart.add(item);
      }
      _cartController.add(_localCart);
      return;
    }

    try {
      String userId = _firebaseService.currentUser!.uid;
      DocumentReference cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('cart_items');

      // Get current cart
      DocumentSnapshot cartDoc = await cartRef.get();
      List<dynamic> items = [];

      if (cartDoc.exists) {
        items = cartDoc.get('items') ?? [];
      }

      // Check if item already exists
      int existingIndex =
          items.indexWhere((i) => i['productId'] == item.productId);

      if (existingIndex >= 0) {
        // Update quantity
        items[existingIndex]['quantity'] = items[existingIndex]['quantity'] + 1;
      } else {
        // Add new item
        items.add(item.toMap());
      }

      // Save to Firestore
      await cartRef.set({'items': items});

      // Update the stream
      List<CartItem> cartItems = items.map((i) => CartItem.fromMap(i)).toList();
      _cartController.add(cartItems);
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  // Get cart items
  Future<List<CartItem>> getCartItems() async {
    if (!_firebaseService.isLoggedIn) {
      return _localCart;
    }

    try {
      String userId = _firebaseService.currentUser!.uid;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('cart_items')
          .get();

      if (doc.exists) {
        List<dynamic> items = doc.get('items') ?? [];
        return items.map((i) => CartItem.fromMap(i)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  // Clear cart when logging out
  void clearLocalCart() {
    _localCart = [];
    _cartController.add(_localCart);
  }

  void dispose() {
    _cartController.close();
  }
}
