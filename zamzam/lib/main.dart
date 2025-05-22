import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/main_page.dart';
import 'pages/products_page.dart';
import 'pages/cart_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/payment_page.dart';
import 'pages/profile_page.dart';
import 'pages/welcome_page.dart';
import 'pages/admin_page.dart';
import 'pages/firebase_products_page.dart';
import 'pages/checkout_page.dart';
import 'pages/admin_orders_page.dart';
import 'pages/make_admin_page.dart';
import 'pages/list_users_page.dart'; // Import the ListUsersPage
import 'services/firebase_service.dart';
import 'pages/language_settings_page.dart';
import 'pages/help_support_page.dart';
import 'pages/order_history_page.dart';
import 'pages/tracking_page.dart';
import 'pages/add_product.dart';
import 'pages/delete_product.dart';
import 'pages/update_product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBoDgHy2QTAfjd_u0ax6GlAXvUKpsRaCSs",
      authDomain: "zamzam-bc5f4.firebaseapp.com",
      projectId: "zamzam-bc5f4",
      storageBucket: "zamzam-bc5f4.firebasestorage.app",
      messagingSenderId: "30898983062",
      appId: "1:30898983062:web:b43f5874bbe8c9ba61f2b7",
      measurementId: "G-T7H96FNS6C",
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(ZamZamApp());
}

class ZamZamApp extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zamzam Stationery',
      theme: ThemeData(
          // ...existing code...
          ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomePage(),
        '/main': (context) => MainPage(),
        '/products': (context) => ProductsPage(),
        '/cart': (context) => CartPage(),
        '/wishlist': (context) => WishlistPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/payment': (context) => PaymentPage(),
        '/profile': (context) => ProfilePage(),
        '/firebase-products': (context) => FirebaseProductsPage(),
        '/checkout': (context) => CheckoutPage(),
        '/admin': (context) => _buildAdminRoute(context, AdminPage()),
        '/make-admin': (context) => _buildAdminRoute(context, MakeAdminPage()),
        '/admin/orders': (context) =>
            _buildAdminRoute(context, AdminOrdersPage()), // Update Orders Page
        '/list-users': (context) => _buildAdminRoute(context, ListUsersPage()),
        '/add_product': (context) =>
            _buildAdminRoute(context, AddProductPage()),
        '/delete_product': (context) =>
            _buildAdminRoute(context, DeleteProductPage()),
        '/update_product': (context) =>
            _buildAdminRoute(context, UpdateProductPage()),
        '/language': (context) => LanguageSettingsPage(),
        '/help': (context) => HelpSupportPage(), // View All Users Page
        '/order-history': (context) => OrderHistoryPage(),
        '/tracking': (context) => TrackingPage(),
      },
    );
  }

  Widget _buildAdminRoute(BuildContext context, Widget page) {
    return FutureBuilder<bool>(
      future: _firebaseService.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return page;
        }

        return Scaffold(
          appBar: AppBar(title: Text('Access Denied')),
          body: Center(
              child: Text('You do not have permission to access this page.')),
        );
      },
    );
  }
}
