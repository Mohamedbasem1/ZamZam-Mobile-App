import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class TrackingPage extends StatelessWidget {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Order')),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orderService
            .getTrackingOrders(), // Call the getTrackingOrders function
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data;

          if (orders == null || orders.isEmpty) {
            return Center(child: Text('No orders found for tracking.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Order ID: ${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status}'),
                      Text('Total: ${order.total.toStringAsFixed(2)} EGP'),
                      Text('Created At: ${order.createdAt.toLocal()}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navigate to order details page (if implemented)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
