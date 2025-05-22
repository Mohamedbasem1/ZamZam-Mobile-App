import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/firebase_service.dart';

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final OrderService _orderService = OrderService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      // Use the FirebaseService function to check if the current user is an admin
      final isAdmin = await _firebaseService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
      });
      print('Error checking admin status: $e');
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'processing':
        return '#4169E1'; // Royal Blue
      case 'shipped':
        return '#32CD32'; // Lime Green
      case 'delivered':
        return '#008000'; // Green
      case 'cancelled':
        return '#FF0000'; // Red
      default:
        return '#808080'; // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Orders')),
        body: Center(child: Text('Access Denied: Admin Only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('Order #${order.id.substring(0, 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status}',
                          style: TextStyle(
                            color: Color(int.parse(
                                    _getStatusColor(order.status)
                                        .substring(1, 7),
                                    radix: 16) +
                                0xFF000000),
                          )),
                      Text('Total: EGP ${order.total.toStringAsFixed(2)}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer Details:'),
                          Text('Name: ${order.userName}'),
                          Text('Email: ${order.userEmail}'),
                          Text('Phone: ${order.phone}'),
                          Text('Address: ${order.address}'),
                          Divider(),
                          Text('Order Items:'),
                          ...order.items.map((item) => ListTile(
                                leading: Image.network(
                                  item.image,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported),
                                ),
                                title: Text(item.name),
                                subtitle:
                                    Text('${item.quantity}x ${item.price}'),
                              )),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Subtotal: EGP ${order.subtotal.toStringAsFixed(2)}'),
                              Text(
                                  'Shipping: EGP ${order.shippingFee.toStringAsFixed(2)}'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total: EGP ${order.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownButton<String>(
                            value: order.status,
                            items: [
                              'pending',
                              'processing',
                              'shipped',
                              'delivered',
                              'cancelled'
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) async {
                              if (newValue != null) {
                                try {
                                  await _orderService.updateOrderStatus(
                                      order.id, newValue);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Order status updated'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to update status: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
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
    );
  }
}
