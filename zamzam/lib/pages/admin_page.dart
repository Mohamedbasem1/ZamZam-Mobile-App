import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'make_admin_page.dart';
import 'list_users_page.dart';
import 'dart:ui';

/// Modern color palette for the Admin Dashboard
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF3F51B5);      // Indigo
  static const Color primaryDark = Color(0xFF303F9F);  // Dark Indigo
  static const Color primaryLight = Color(0xFFE8EAF6); // Light Indigo

  // Section colors
  static const Color orders = Color(0xFF5C6BC0);       // Indigo 400
  static const Color ordersLight = Color(0xFFE8EAF6);  // Indigo 50

  static const Color users = Color(0xFF26A69A);        // Teal 400
  static const Color usersLight = Color(0xFFE0F2F1);   // Teal 50

  static const Color products = Color(0xFFFF7043);     // Deep Orange 400
  static const Color productsLight = Color(0xFFFBE9E7); // Deep Orange 50

  // UI colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color text = Color(0xFF2A3747);
  static const Color textSecondary = Color(0xFF6B7A8D);
}

class AdminPage extends StatelessWidget {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? (screenWidth - 48) / 2 : screenWidth - 32;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Welcome, Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SectionCard(
                  width: cardWidth,
                  icon: Icons.shopping_cart_outlined,
                  title: 'Orders',
                  color: AppColors.orders,
                  lightColor: AppColors.ordersLight,
                  actions: [
                    SectionAction(
                      icon: Icons.refresh,
                      label: 'Sync Orders',
                      onTap: () => Navigator.pushNamed(context, '/admin/orders'),
                    ),
                    SectionAction(
                      icon: Icons.list_alt,
                      label: 'View Orders',
                      onTap: () => Navigator.pushNamed(context, '/admin/orders'),
                    ),
                  ],
                ),
                SectionCard(
                  width: cardWidth,
                  icon: Icons.people_outline,
                  title: 'Users',
                  color: AppColors.users,
                  lightColor: AppColors.usersLight,
                  actions: [
                    SectionAction(
                      icon: Icons.admin_panel_settings,
                      label: 'Make Admin',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MakeAdminPage()),
                      ),
                    ),
                    SectionAction(
                      icon: Icons.people,
                      label: 'All Users',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ListUsersPage()),
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  width: cardWidth,
                  icon: Icons.inventory_2_outlined,
                  title: 'Products',
                  color: AppColors.products,
                  lightColor: AppColors.productsLight,
                  actions: [
                    SectionAction(
                      icon: Icons.add_circle_outline,
                      label: 'Add Product',
                      onTap: () => Navigator.pushNamed(context, '/add_product'),
                    ),
                    SectionAction(
                      icon: Icons.delete_outline,
                      label: 'Delete Product',
                      onTap: () => Navigator.pushNamed(context, '/delete_product'),
                    ),
                    SectionAction(
                      icon: Icons.edit_outlined,
                      label: 'Update Product',
                      onTap: () => Navigator.pushNamed(context, '/update_product'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final Color color;
  final Color lightColor;
  final List<SectionAction> actions;

  const SectionCard({
    Key? key,
    required this.width,
    required this.icon,
    required this.title,
    required this.color,
    required this.lightColor,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightColor,
                  border: Border(
                    bottom: BorderSide(color: color.withOpacity(0.1), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    SizedBox(width: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Card actions
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions.map((action) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                        ),
                      ),
                      onPressed: action.onTap,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, size: 20),
                          SizedBox(width: 8),
                          Text(
                            action.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  SectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}