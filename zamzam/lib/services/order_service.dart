import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'firebase_service.dart';
import 'cart_service.dart';
import 'package:uuid/uuid.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final CartService _cartService = CartService();
  final _uuid = Uuid();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  // Create a new order
  Future<String> createOrder({
    required String address,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to create an order');
      }

      final user = _firebaseService.currentUser!;
      final cartItems = await _cartService.getCartItemsStream().first;
      
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      double subtotal = 0;
      List<OrderItem> orderItems = cartItems.map((item) {
        double price = double.tryParse(item.price.replaceAll('EGP', '').trim()) ?? 0;
        subtotal += price * item.quantity;
        
        return OrderItem(
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          image: item.image,
        );
      }).toList();

      const double shippingFee = 25.0;
      final double total = subtotal + shippingFee;

      final String orderId = _uuid.v4();
      final ShopOrder order = ShopOrder(
        id: orderId,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userEmail: user.email ?? '',
        address: address,
        phone: phone,
        items: orderItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        status: 'pending',
        createdAt: DateTime.now(),
        paymentMethod: paymentMethod,
      );

      // Save order to Firestore
      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      // Clear the cart after successful order creation
      await _cartService.clearCart();

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Get user's orders
  Stream<List<ShopOrder>> getUserOrders() {
    if (!_firebaseService.isLoggedIn) {
      return Stream.value([]);
    }

    final userId = _firebaseService.currentUser!.uid;
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShopOrder.fromMap(doc.data());
      }).toList();
    });
  }

  // Get all orders (admin only)
  Stream<List<ShopOrder>> getAllOrders() async* {
    if (!_firebaseService.isLoggedIn) {
      yield [];
      return;
    }

    final isAdmin = await _firebaseService.isAdmin;
    if (!isAdmin) {
      yield [];
      return;
    }

    try {
      yield* _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ShopOrder.fromMap(doc.data());
        }).toList();
      });
    } catch (e) {
      print('Error getting all orders: $e');
      yield [];
    }
  }

  // Update order status (admin only)
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!_firebaseService.isLoggedIn) {
      throw Exception('User must be logged in to update order status');
    }

    final isAdmin = await _firebaseService.isAdmin;
    if (!isAdmin) {
      throw Exception('Only admins can update order status');
    }

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  // Get single order
  Future<ShopOrder> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        throw Exception('Order not found');
      }
      return ShopOrder.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting order: $e');
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }
} 