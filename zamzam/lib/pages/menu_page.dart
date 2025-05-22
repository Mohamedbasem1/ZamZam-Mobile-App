import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Contact'),
            onTap: () => Navigator.pushNamed(context, '/contact'),
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Cart'),
            onTap: () => Navigator.pushNamed(context, '/cart'),
          ),
          ListTile(
            leading: Icon(Icons.track_changes),
            title: Text('Tracking'),
            onTap: () => Navigator.pushNamed(context, '/tracking'),
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text('Wishlist'),
            onTap: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payment'),
            onTap: () => Navigator.pushNamed(context, '/payment'),
          ),
        ],
      ),
    );
  }
}
