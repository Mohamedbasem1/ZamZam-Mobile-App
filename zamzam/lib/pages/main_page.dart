import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/cart_service.dart'; // Add this import
import 'home_page.dart';
import 'products_page.dart';
import 'wishlist_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'welcome_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  final CartService _cartService = CartService();
  bool _isLoggedIn = false;

  // Update this property to hold the selected category
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Check initial login state
    _isLoggedIn = _firebaseService.isLoggedIn;

    // Listen for auth state changes
    _firebaseService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });

        // Clear local cart on sign out
        if (user == null) {
          _cartService.clearLocalCart();
        }

        // If user signs out while in a protected tab, redirect to home tab
        if (user == null &&
            (_selectedIndex == 2 ||
                _selectedIndex == 3 ||
                _selectedIndex == 4)) {
          _selectedIndex = 0;
          // Navigate to welcome page
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      }
    });
  }

  @override
  void dispose() {
    // We'll let the CartService handle its own lifecycle
    // Don't dispose the CartService here since it's a singleton
    // and might be used by other parts of the app
    super.dispose();
  }

  // Navigate to a specific tab and optionally pass data
  void _onItemTapped(int index, {String? category}) {
    // Protected tabs that require login
    if ((index == 2 || index == 3 || index == 4) && !_isLoggedIn) {
      Navigator.pushNamed(context, '/welcome');
      return;
    }

    // If category is provided, update the selected category
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
              onNavigate: (index, {String? category}) =>
                  _onItemTapped(index, category: category)),
          ProductsPage(
            selectedCategory: _selectedCategory,
            onNavigate: (index) => _onItemTapped(index),
          ),
          _isLoggedIn
              ? WishlistPage(onNavigate: (index) => _onItemTapped(index))
              : WelcomePage(),
          _isLoggedIn
              ? CartPage(onNavigate: (index) => _onItemTapped(index))
              : WelcomePage(),
          _isLoggedIn ? ProfilePage() : WelcomePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          // Wishlist with dynamic icon
          BottomNavigationBarItem(
            icon: Icon(_isLoggedIn ? Icons.favorite : Icons.favorite_border),
            label: 'Wishlist',
          ),
          // Cart with dynamic icon
          BottomNavigationBarItem(
            icon: Icon(_isLoggedIn
                ? Icons.shopping_cart
                : Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          // Profile with dynamic icon
          BottomNavigationBarItem(
            icon: Icon(_isLoggedIn ? Icons.person : Icons.person_outline),
            label: _isLoggedIn ? 'Profile' : 'Sign In',
          ),
        ],
      ),
    );
  }
}
