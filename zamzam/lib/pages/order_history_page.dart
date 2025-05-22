import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderHistoryPage extends StatelessWidget {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orderService
            .getOrderHistory(), // Call the getOrderHistory function
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(child: Text('No order history found.'));
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
                            color: order.status.toLowerCase() == 'delivered'
                                ? Colors.green
                                : Colors.red,
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
