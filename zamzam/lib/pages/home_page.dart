import 'package:flutter/material.dart';
import '../services/product_firebase_service.dart';
import '../services/firebase_service.dart';
import '../services/cart_service.dart';
import '../constants/image_constants.dart';
import '../services/api_services.dart' show Product;
import '../services/favorite_service.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/product_detail_dialog.dart';

class HomePage extends StatefulWidget {
  final Function(int, {String? category})? onNavigate;

  HomePage({this.onNavigate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();
  final ProductFirebaseService _productService = ProductFirebaseService();
  final CartService _cartService = CartService();
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseService _firebaseService = FirebaseService();

  final List<Map<String, dynamic>> _banners = ImageConstants.banners;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pens', 'icon': Icons.edit, 'color': Color(0xFF5B61F4)},
    {'name': 'Notebooks', 'icon': Icons.menu_book, 'color': Color(0xFFF46363)},
    {'name': 'Art Supplies', 'icon': Icons.brush, 'color': Color(0xFF01B075)},
    {'name': 'Montblanc', 'icon': Icons.star, 'color': Color(0xFFF8AE33)},
    {'name': 'Pilot', 'icon': Icons.auto_awesome, 'color': Color(0xFF985EFF)},
  ];

  int _cartItemCount = 0;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    // Load cart count
    _loadCartCount();

    // Listen for cart changes
    _cartService.cartStream.listen((_) {
      if (mounted) {
        _loadCartCount();
      }
    });
  }

  Future<void> _loadCartCount() async {
    final count = await _cartService.getCartCount();
    if (mounted) {
      setState(() {
        _cartItemCount = count;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zamzam'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(3);
                  } else {
                    Navigator.pushNamed(context, '/cart');
                  }
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh featured products
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  height: 50,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for products...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF9CA4AB)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onTap: () {
                      // Navigate to browse tab when search is tapped
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(1);
                      }
                    },
                    readOnly: true, // Make it non-editable
                  ),
                ),

                // Banner Carousel
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: AssetImage(_banners[index]['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _banners.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentCarouselIndex == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Categories
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                SizedBox(height: 16),

                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to browse tab with selected category
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(1, category: category['name']);
                          } else {
                            // Fallback: Use named route with arguments
                            Navigator.pushNamed(context, '/products',
                                arguments: {'category': category['name']});
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: category['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: category['color'],
                                  size: 28,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24),

                // Featured Products
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Products',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Browse/Products page
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(1);
                        } else {
                          Navigator.pushNamed(context, '/products');
                        }
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Featured products from Firebase
                FutureBuilder<List<Product>>(
                  future: _productService.getFeaturedProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Failed to load products'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text('No featured products available'),
                      );
                    }

                    final products = snapshot.data!;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length > 4 ? 4 : products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(product);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Show product details dialog
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailDialog(
            product: product,
            onNavigate: widget.onNavigate,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey)),
                    ),
                  ),
                  if (product.stockCount == 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (product.isFeatured)
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        StreamBuilder<List<Product>>(
                          stream: _favoriteService.getFavoriteProductsStream(),
                          builder: (context, snapshot) {
                            bool isFavorite = false;
                            if (snapshot.hasData) {
                              isFavorite = snapshot.data!.any((p) => p.docId == product.docId);
                            }
                            
                            return GestureDetector(
                              onTap: () async {
                                if (!_firebaseService.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please login to add to favorites'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'LOGIN',
                                        onPressed: () {
                                          // Navigate to login page
                                          Navigator.pushNamed(context, '/login');
                                        },
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                
                                try {
                                  await _favoriteService.toggleFavorite(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite
                                            ? 'Removed from favorites'
                                            : 'Added to favorites',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update favorites'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFC107),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${product.rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(${product.ratingCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.price,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stockCount > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.stockCount > 0 ? 'In Stock' : 'Out',
                          style: TextStyle(
                            color: product.stockCount > 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
