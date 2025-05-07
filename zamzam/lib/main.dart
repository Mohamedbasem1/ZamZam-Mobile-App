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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAp83c3ABi2Pj7s0sdzw2VXd-wQ9Hgugls",
      authDomain: "zamzam-72a96.firebaseapp.com",
      databaseURL: "https://zamzam-72a96-default-rtdb.firebaseio.com",
      projectId: "zamzam-72a96",
      storageBucket: "zamzam-72a96.firebasestorage.app",
      messagingSenderId: "597516704822",
      appId: "1:597516704822:web:61d74ca1aa54f723834c97",
      measurementId: "G-5V2JMBXKFD",
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
      },
    );
  }
}
