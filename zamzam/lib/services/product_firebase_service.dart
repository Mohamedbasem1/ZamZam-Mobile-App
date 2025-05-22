import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_services.dart';
import '../services/firebase_service.dart';

class ProductFirebaseService {
  static final ProductFirebaseService _instance =
      ProductFirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  factory ProductFirebaseService() {
    return _instance;
  }

  ProductFirebaseService._internal();

  // Collection references
  CollectionReference get _productsCollection =>
      _firestore.collection('Products');
  CollectionReference get _featuredProductsCollection =>
      _firestore.collection('featured_products');
  CollectionReference get _categoriesCollection =>
      _firestore.collection('categories');

  // Helper method to create a valid document ID from URL
  String _createDocumentId(String url) {
    // Remove invalid characters and replace with underscores
    return url
        .replaceAll(
            RegExp(r'[^\w\s-]'), '_') // Replace invalid chars with underscore
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .toLowerCase(); // Convert to lowercase
  }

  // Save a list of products to Firebase
  Future<void> saveProducts(List<Product> products) async {
    try {
      // Create a batch write to perform multiple operations
      WriteBatch batch = _firestore.batch();

      // Get the current highest ID from the collection
      int nextId = await _getNextProductId();

      // Add each product to the batch
      for (var product in products) {
        String docId = _createDocumentId(product.url);
        DocumentReference docRef = _productsCollection.doc(docId);

        // Create a new product with the next ID
        Product updatedProduct = Product(
          name: product.name,
          price: product.price,
          image: product.image,
          url: product.url,
          nameUrl: product.nameUrl,
          rating: product.rating,
          ratingCount: product.ratingCount,
          isFeatured: product.isFeatured,
          docId: docId,
          id: nextId,
          stockCount: 1 +
              (DateTime.now().millisecondsSinceEpoch %
                  150), // Random stock between 1 and 150
        );

        Map<String, dynamic> data = updatedProduct.toMap();

        // Ensure price is stored as a numeric value
        if (data['price'] is String) {
          // Remove 'EGP' and any other non-numeric characters
          String cleanPrice =
              data['price'].toString().replaceAll('EGP', '').trim();
          data['price'] = double.tryParse(cleanPrice) ?? 0.0;
        }

        batch.set(docRef, data, SetOptions(merge: true));

        nextId++; // Increment ID for next product
      }

      // Commit the batch
      await batch.commit();
      print('Products saved to Firebase successfully');
    } catch (e) {
      print('Error saving products to Firebase: $e');
      throw Exception('Failed to save products to Firebase: $e');
    }
  }

  // Helper method to get the next available product ID
  Future<int> _getNextProductId() async {
    try {
      // Query the collection ordered by ID in descending order and get the first document
      final QuerySnapshot snapshot = await _productsCollection
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 1; // Start with ID 1 if no products exist
      }

      // Get the highest ID and add 1
      final highestId =
          (snapshot.docs.first.data() as Map<String, dynamic>)['id'] as int;
      return highestId + 1;
    } catch (e) {
      print('Error getting next product ID: $e');
      return 1; // Return 1 if there's an error
    }
  }

  // Save featured products to Firebase
  Future<void> saveFeaturedProducts(List<Product> featuredProducts) async {
    try {
      // Create a batch write to perform multiple operations
      WriteBatch batch = _firestore.batch();

      // Add each featured product to the batch
      for (var product in featuredProducts) {
        String docId = _createDocumentId(product.url);
        DocumentReference docRef = _featuredProductsCollection.doc(docId);
        Map<String, dynamic> data = product.toMap();
        data['docId'] = docId; // Store the document ID in the document itself
        batch.set(docRef, data, SetOptions(merge: true));
      }

      // Commit the batch
      await batch.commit();
      print('Featured products saved to Firebase successfully');
    } catch (e) {
      print('Error saving featured products to Firebase: $e');
      throw Exception('Failed to save featured products to Firebase: $e');
    }
  }

  // Save product categories to Firebase
  Future<void> saveCategories(List<String> categories) async {
    try {
      await _categoriesCollection.doc('categories').set({
        'list': categories,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Categories saved to Firebase successfully');
    } catch (e) {
      print('Error saving categories to Firebase: $e');
      throw Exception('Failed to save categories to Firebase: $e');
    }
  }

  // Get all products from Firebase
  Future<List<Product>> getProducts() async {
    try {
      QuerySnapshot snapshot = await _productsCollection.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return Product.fromFirebase(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting products from Firebase: $e');
      return [];
    }
  }

  // Get featured products from Firebase
  Future<List<Product>> getFeaturedProducts() async {
    try {
      QuerySnapshot snapshot = await _featuredProductsCollection
          .orderBy('rating', descending: true) // Sort by rating
          .limit(4) // Limit to 4 items
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return Product.fromFirebase(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting featured products from Firebase: $e');
      return [];
    }
  }

  // Get product categories from Firebase
  Future<List<String>> getCategories() async {
    try {
      DocumentSnapshot snapshot =
          await _categoriesCollection.doc('categories').get();

      if (!snapshot.exists) {
        return [];
      }

      List<dynamic> categoriesList = snapshot.get('list') ?? [];
      return categoriesList.map((category) => category.toString()).toList();
    } catch (e) {
      print('Error getting categories from Firebase: $e');
      return [];
    }
  }

  // Get a specific product by URL
  Future<Product?> getProductByUrl(String url) async {
    try {
      String docId = _createDocumentId(url);
      DocumentSnapshot doc = await _productsCollection.doc(docId).get();

      if (!doc.exists) {
        return null;
      }

      return Product.fromFirebase(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting product from Firebase: $e');
      return null;
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      if (category.toLowerCase() == 'all') {
        return await getProducts();
      }

      // First, try to get products from Firebase
      final allProducts = await getProducts();

      // Print debug information
      print('Category: $category, Total products: ${allProducts.length}');

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

      print('Filtered products count: ${filteredProducts.length}');

      // If no products found after filtering, try to sync from API
      if (filteredProducts.isEmpty) {
        print(
            'No products found for category: $category. Trying to get from API...');
        // This is just a fallback and won't be executed unless you call it explicitly
      }

      return filteredProducts;
    } catch (e) {
      print('Error getting products by category from Firebase: $e');
      return [];
    }
  }
}
