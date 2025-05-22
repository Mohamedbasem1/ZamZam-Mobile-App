import 'package:flutter/material.dart';
import '../services/product_firebase_service.dart';
import '../services/cart_service.dart';
import '../services/firebase_service.dart';
import '../services/api_services.dart' show Product;
import '../services/favorite_service.dart';
import '../services/sync_products.dart';
import '../widgets/product_detail_dialog.dart';

class ProductsPage extends StatefulWidget {
  final String? selectedCategory;
  final Function(int)? onNavigate;

  const ProductsPage({this.selectedCategory, this.onNavigate});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with SingleTickerProviderStateMixin {
  final ProductFirebaseService _productService = ProductFirebaseService();
  final CartService _cartService = CartService();
  final FirebaseService _firebaseService = FirebaseService();
  final FavoriteService _favoriteService = FavoriteService();
  final SyncProductsService _syncService = SyncProductsService();

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearchFocused = false;
  late AnimationController _animationController;
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  String? _error;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  int _cartItemCount = 0;
  int _selectedCategoryIndex = 0;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _loadInitialData();
    _loadCartCount();

    _cartService.cartStream.listen((_) {
      if (mounted) {
        _loadCartCount();
      }
    });
  }

  @override
  void didUpdateWidget(ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _handleCategoryChange();
    }
  }

  void _handleCategoryChange() async {
    if (widget.selectedCategory != null) {
      // Find the index of the selected category
      int index = _categories.indexWhere((category) =>
          category.toLowerCase() == widget.selectedCategory!.toLowerCase());
      if (index != -1) {
        setState(() {
          _selectedCategoryIndex = index;
        });
        await _loadProducts();
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _isCategoriesLoading = true;
        _error = null;
      });

      // Load categories from Firebase
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() {
          _categories = ['All', ...categories];
          _isCategoriesLoading = false;
        });
      }

      // Initialize selected category if one was passed
      await _initializeCategory();

      // Load products based on selected category
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
          _isLoading = false;
          _isCategoriesLoading = false;
        });
      }
    }
  }

  Future<void> _initializeCategory() async {
    if (widget.selectedCategory != null) {
      for (int i = 0; i < _categories.length; i++) {
        if (_categories[i].toLowerCase() ==
            widget.selectedCategory?.toLowerCase()) {
          setState(() {
            _selectedCategoryIndex = i;
          });
          break;
        }
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<Product> products;
      if (_selectedCategoryIndex == 0) {
        // Load all products
        products = await _productService.getProducts();
        print('Loaded all products: ${products.length}');
      } else {
        // Load products by category
        String category = _categories[_selectedCategoryIndex];
        print('Loading products for category: $category');
        products = await _productService.getProductsByCategory(category);
        print('Loaded ${products.length} products for category: $category');
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filterProducts(); // Apply search filter if any
          _isLoading = false;
        });

        // If no products were found, try to sync from API
        if (products.isEmpty) {
          print('No products found. Attempting to sync from API...');
          _syncProducts();
        }
      }
    } catch (e) {
      print('Error in _loadProducts: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading products: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts() {
    if (_allProducts.isEmpty) return;

    List<Product> filtered = List.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
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

  Future<void> _syncProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Starting product synchronization...');
      await _syncService.syncProductsToFirebase();
      print('Products synchronized successfully');

      // Reload products after sync
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Products synchronized successfully')),
        );
      }
    } catch (e) {
      print('Error syncing products: $e');
      if (mounted) {
        setState(() {
          _error = 'Error syncing products: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                title: Text('Browse Products'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.sync),
                    onPressed: _syncProducts,
                  ),
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
            ];
          },
          body: Column(
            children: [
              // Search Bar
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: _isSearchFocused ? 8 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _isSearchFocused
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      _isSearchFocused = hasFocus;
                      if (hasFocus) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    });
                  },
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterProducts();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchFocused
                            ? Theme.of(context).colorScheme.primary
                            : Color(0xFF9CA4AB),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = "";
                                  _filterProducts();
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              // Categories
              if (_isCategoriesLoading)
                Container(
                  height: 50,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Container(
                  height: 50,
                  margin: EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_categories[index]),
                          selected: _selectedCategoryIndex == index,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                              _loadProducts(); // Reload products when category changes
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Products Grid
              Expanded(
                child: _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInitialData,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _filteredProducts.isEmpty
                            ? Center(
                                child: Text('No products found'),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadProducts,
                                child: GridView.builder(
                                  padding: EdgeInsets.all(16),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),
                              ),
              ),
            ],
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
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
                              isFavorite = snapshot.data!
                                  .any((p) => p.docId == product.docId);
                            }

                            return GestureDetector(
                              onTap: () async {
                                if (!_firebaseService.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please login to add to favorites'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'LOGIN',
                                        onPressed: () {
                                          // Navigate to login page
                                          Navigator.pushNamed(
                                              context, '/login');
                                        },
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await _favoriteService
                                      .toggleFavorite(product);
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
                                      content:
                                          Text('Failed to update favorites'),
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
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stockCount > 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.stockCount > 0 ? 'In Stock' : 'Out',
                          style: TextStyle(
                            color: product.stockCount > 0
                                ? Colors.green
                                : Colors.red,
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
