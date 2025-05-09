import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final OrderService _orderService = OrderService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  Future<void> _generateInvoice(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Invoice', style: pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Order ID: ${order.id}'),
                      pw.Text('Date: ${_dateFormat.format(order.createdAt)}'),
                      pw.Text('Status: ${order.status}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Customer Details:'),
                      pw.Text(order.userName),
                      pw.Text(order.userEmail),
                      pw.Text(order.phone),
                      pw.Text(order.address),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Table.fromTextArray(
                headers: ['Item', 'Quantity', 'Price', 'Total'],
                data: order.items.map((item) {
                  double price = double.tryParse(
                        item.price.replaceAll('EGP', '').trim(),
                      ) ??
                      0;
                  return [
                    item.name,
                    item.quantity.toString(),
                    'EGP ${price.toStringAsFixed(2)}',
                    'EGP ${(price * item.quantity).toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('EGP ${order.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Shipping:'),
                  pw.Text('EGP ${order.shippingFee.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('EGP ${order.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('Payment Method: ${order.paymentMethod}'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _updateOrderStatus(Order order, String status) async {
    try {
      await _orderService.updateOrderStatus(order.id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
      ),
      body: StreamBuilder<List<Order>>(
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
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dateFormat.format(order.createdAt)),
                      Text(
                        'Status: ${order.status}',
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text('Name: ${order.userName}'),
                          Text('Email: ${order.userEmail}'),
                          Text('Phone: ${order.phone}'),
                          Text('Address: ${order.address}'),
                          SizedBox(height: 16),
                          Text(
                            'Order Items',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          ...order.items.map(
                            (item) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} x ${item.quantity}',
                                    ),
                                  ),
                                  Text(item.price),
                                ],
                              ),
                            ),
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal'),
                              Text(
                                'EGP ${order.subtotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Shipping'),
                              Text(
                                'EGP ${order.shippingFee.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'EGP ${order.total.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: order.status,
                                  decoration: InputDecoration(
                                    labelText: 'Update Status',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    'pending',
                                    'processing',
                                    'shipped',
                                    'delivered',
                                    'cancelled',
                                  ].map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _updateOrderStatus(order, value);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _generateInvoice(order),
                                icon: Icon(Icons.receipt_long),
                                label: Text('Invoice'),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 