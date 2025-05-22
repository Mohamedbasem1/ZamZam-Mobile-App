import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/image_constants.dart'; // Add this import

// Product Model
class Product {
  final String name;
  final String price;
  final String image;
  final String url;
  final String nameUrl;
  double rating;
  int ratingCount;
  bool isFeatured;
  String? docId;
  int id; // Add numerical ID
  int stockCount; // Add stock count

  Product({
    required this.name,
    required this.price,
    required this.image,
    required this.url,
    required this.nameUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFeatured = false,
    this.docId,
    required this.id, // Add this
    required this.stockCount, // Add this
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Keep price as is from API
    String priceStr = json['Price'] ?? 'EGP 0.00';

    // Generate a random stock count between 1 and 150
    final random = DateTime.now().millisecondsSinceEpoch;
    final stockCount = 1 + (random % 150);

    return Product(
      name: json['Name'] ?? 'Unnamed Product',
      price: priceStr,
      image: json['image'] ?? '',
      url: json['url'] ?? '',
      nameUrl: json['Name_url'] ?? '',
      id: json['id'] ?? 0, // This will be set later
      stockCount: stockCount,
    );
  }

  // Add method to convert Product to Map for Firebase
  Map<String, dynamic> toMap() {
    // Convert price to a clean numeric value for storage
    double numericPrice;
    // Always treat price as a string and extract numeric value
    String cleanPrice = price.toString().replaceAll('EGP', '').trim();
    numericPrice = double.tryParse(cleanPrice) ?? 0.0;

    return {
      'name': name,
      'price': numericPrice,
      'image': image,
      'url': url,
      'nameUrl': nameUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFeatured': isFeatured,
      'docId': docId,
      'id': id,
      'stockCount': stockCount,
    };
  }

  // Add method to create Product from Firebase data
  factory Product.fromFirebase(Map<String, dynamic> data) {
    // Convert price to string, handling different input types
    String price;
    if (data['price'] is double) {
      price = 'EGP ${data['price'].toStringAsFixed(2)}';
    } else if (data['price'] is int) {
      price = 'EGP ${data['price'].toDouble().toStringAsFixed(2)}';
    } else {
      price = data['price'] ?? 'EGP 0.00';
    }

    return Product(
      name: data['name'] ?? 'Unnamed Product',
      price: price,
      image: data['image'] ?? '',
      url: data['url'] ?? '',
      nameUrl: data['nameUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: (data['ratingCount'] ?? 0).toInt(),
      isFeatured: data['isFeatured'] ?? false,
      docId: data['docId'],
      id: data['id'] ?? 0,
      stockCount: data['stockCount'] ?? 0,
    );
  }
}

class ApiService {
  static const String apiEndpoint =
      'https://www.parsehub.com/api/v2/projects/t52hHxjvgZKM/last_ready_run/data?api_key=twaTYcajQSyT';

  // Update featured products data with school/library themed images
  static final List<Map<String, dynamic>> _featuredProductsData = [
    {
      'name': 'Premium Fountain Pen, Midnight Blue',
      'price': 'EGP 700.00',
      'rating': 4.8,
      'ratingCount': 254,
      'image': ImageConstants.montblancMidnightBlue,
      'isFeatured': true
    },
    {
      'name': 'Luxury Writing Set, Black Edition',
      'price': 'EGP 650.00',
      'rating': 4.5,
      'ratingCount': 189,
      'image': ImageConstants.montblancMysteryBlack,
      'isFeatured': true
    },
    {
      'name': 'Professional Notebook, Royal Blue',
      'price': 'EGP 120.00',
      'rating': 4.7,
      'ratingCount': 132,
      'image': ImageConstants.montblancRoyalBlue,
      'isFeatured': true
    },
    {
      'name': 'Student Ballpoint Pen Set',
      'price': 'EGP 55.00',
      'rating': 4.9,
      'ratingCount': 95,
      'image': ImageConstants.pilotBallpoint,
      'isFeatured': true
    },
  ];

  // Categories for filtering
  static final List<String> productCategories = [
    'All',
    'Pens',
    'Notebooks',
    'Art Supplies',
    'Ink',
    'Montblanc',
    'Pilot'
  ];

  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiEndpoint));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> productsJson = jsonData['Products'] ?? [];

        List<Product> products = productsJson
            .map((productJson) => Product.fromJson(productJson))
            .toList();

        // Enhance certain products with featured status and ratings
        for (var product in products) {
          // Find if this product matches any of our featured products
          var featuredMatch = _featuredProductsData.firstWhere(
            (featuredProduct) => product.name.contains(featuredProduct['name']),
            orElse: () => {},
          );

          if (featuredMatch.isNotEmpty) {
            product.rating = featuredMatch['rating'];
            product.ratingCount = featuredMatch['ratingCount'];
            product.isFeatured = true;
          } else {
            // Assign random ratings for non-featured products
            product.rating = 3.0 +
                (DateTime.now().millisecond % 20) / 10; // between 3.0 and 5.0
            product.ratingCount =
                10 + (DateTime.now().millisecond % 90); // between 10 and 99
          }
        }

        return products;
      } else {
        print('Failed to load products. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load products from API');
      }
    } catch (e) {
      print('Error fetching products: $e');
      // Return sample data if API fails
      return _getSampleProducts();
    }
  }

  // Get featured products
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final allProducts = await fetchProducts();

      // First try to get products marked as featured
      var featured = allProducts.where((p) => p.isFeatured).toList();

      // If no featured products, take the first 4 most expensive products
      if (featured.isEmpty) {
        allProducts.sort((a, b) {
          double priceA = _extractPriceValue(a.price);
          double priceB = _extractPriceValue(b.price);
          return priceB.compareTo(priceA); // Sort by price descending
        });
        featured = allProducts.take(4).toList();
      }

      return featured;
    } catch (e) {
      return _getSampleProducts();
    }
  }

  // Get products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final allProducts = await fetchProducts();
      print('API Service - Total products: ${allProducts.length}');

      if (category.toLowerCase() == 'all') {
        return allProducts;
      }

      // More robust category filtering
      List<Product> filteredProducts = allProducts.where((product) {
        // Check if product name contains the category name
        bool nameContainsCategory =
            product.name.toLowerCase().contains(category.toLowerCase());

        // Special case for Montblanc
        bool isMontblanc = category.toLowerCase() == 'montblanc' &&
            (product.name.toLowerCase().contains('montblanc') ||
                product.name.toLowerCase().contains('mont blanc'));

        // Special case for Notebooks
        bool isNotebook = category.toLowerCase() == 'notebooks' &&
            (product.name.toLowerCase().contains('notebook') ||
                product.name.toLowerCase().contains('journal') ||
                product.name.toLowerCase().contains('diary'));

        // Special case for Pens
        bool isPen = category.toLowerCase() == 'pens' &&
            (product.name.toLowerCase().contains('pen') ||
                product.name.toLowerCase().contains('ballpoint') ||
                product.name.toLowerCase().contains('fountain'));

        // Special case for Art Supplies
        bool isArtSupply = category.toLowerCase() == 'art supplies' &&
            (product.name.toLowerCase().contains('art') ||
                product.name.toLowerCase().contains('paint') ||
                product.name.toLowerCase().contains('brush') ||
                product.name.toLowerCase().contains('pencil') ||
                product.name.toLowerCase().contains('marker'));

        return nameContainsCategory ||
            isMontblanc ||
            isNotebook ||
            isPen ||
            isArtSupply;
      }).toList();

      print(
          'API Service - Filtered products for category "$category": ${filteredProducts.length}');

      // If no products found after filtering, return sample products for the category
      if (filteredProducts.isEmpty) {
        print(
            'API Service - No products found for category: $category. Returning sample products.');
        return _getSampleProductsForCategory(category);
      }

      return filteredProducts;
    } catch (e) {
      print('API Service - Error getting products by category: $e');
      return _getSampleProductsForCategory(category);
    }
  }

  // Get sample products for a specific category
  static List<Product> _getSampleProductsForCategory(String category) {
    List<Product> sampleProducts = _getSampleProducts();

    if (category.toLowerCase() == 'all') {
      return sampleProducts;
    }

    // Filter sample products by category
    return sampleProducts.where((product) {
      if (category.toLowerCase() == 'notebooks') {
        return product.name.toLowerCase().contains('notebook');
      } else if (category.toLowerCase() == 'pens') {
        return product.name.toLowerCase().contains('pen');
      } else {
        return product.name.toLowerCase().contains(category.toLowerCase());
      }
    }).toList();
  }

  // Helper method to extract price as double from string
  static double _extractPriceValue(String priceString) {
    try {
      // Remove 'EGP' and any other non-numeric characters except decimal point
      String cleanPrice =
          priceString.replaceAll('EGP', '').replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(cleanPrice);
    } catch (e) {
      print('Error parsing price: $e');
      return 0.0;
    }
  }

  // Update the sample product images with higher quality ones
  static List<Product> _getSampleProducts() {
    // Add more sample products, especially for notebooks category
    final List<Map<String, dynamic>> extendedSampleProducts = [
      ..._featuredProductsData,
      {
        'name': 'Premium Notebook, Leather Bound',
        'price': 'EGP 250.00',
        'rating': 4.6,
        'ratingCount': 120,
        'image':
            'https://m.media-amazon.com/images/I/71aCFLIPJsL._AC_UF1000,1000_QL80_.jpg',
        'isFeatured': false,
        'category': 'Notebooks'
      },
      {
        'name': 'Student Notebook, College Ruled',
        'price': 'EGP 45.00',
        'rating': 4.3,
        'ratingCount': 85,
        'image':
            'https://m.media-amazon.com/images/I/71Oc3bCMCKL._AC_UF1000,1000_QL80_.jpg',
        'isFeatured': false,
        'category': 'Notebooks'
      },
      {
        'name': 'Executive Notebook with Pen Holder',
        'price': 'EGP 180.00',
        'rating': 4.7,
        'ratingCount': 65,
        'image':
            'https://m.media-amazon.com/images/I/61Nnz1p4IQL._AC_UF1000,1000_QL80_.jpg',
        'isFeatured': false,
        'category': 'Notebooks'
      }
    ];

    print('Creating ${extendedSampleProducts.length} sample products');

    return extendedSampleProducts
        .map((product) => Product(
              name: product['name'],
              price: product['price'],
              image: product['image'],
              url: '#',
              nameUrl: '#',
              rating: product['rating'],
              ratingCount: product['ratingCount'],
              isFeatured: product['isFeatured'],
              id: extendedSampleProducts.indexOf(product),
              stockCount: 10 +
                  (DateTime.now().millisecondsSinceEpoch %
                      50), // Random stock between 10 and 59
            ))
        .toList();
  }

  // Get product details by ID or URL
  static Future<Product?> getProductDetails(String productUrl) async {
    final allProducts = await fetchProducts();
    try {
      return allProducts.firstWhere((product) => product.url == productUrl);
    } catch (e) {
      return null;
    }
  }
}
