import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final String price;
  final int quantity;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      quantity: map['quantity'] ?? 0,
      image: map['image'] ?? '',
    );
  }
}

class ShopOrder {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String address;
  final String phone;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final DateTime createdAt;
  final String paymentMethod;

  ShopOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.address,
    required this.phone,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'address': address,
      'phone': phone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentMethod': paymentMethod,
    };
  }

  factory ShopOrder.fromMap(Map<String, dynamic> map) {
    return ShopOrder(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      items: List<OrderItem>.from(
        (map['items'] as List).map((item) => OrderItem.fromMap(item)),
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'] ?? 'cash_on_delivery',
    );
  }
} 