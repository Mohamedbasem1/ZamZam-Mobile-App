import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_services.dart';
import '../services/firebase_service.dart';

class ProductFirebaseService {
  static final ProductFirebaseService _instance = ProductFirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  factory ProductFirebaseService() {
    return _instance;
  }

  ProductFirebaseService._internal();

  // Collection references
  CollectionReference get _productsCollection => _firestore.collection('Products');
  CollectionReference get _featuredProductsCollection => _firestore.collection('featured_products');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');

  // Helper method to create a valid document ID from URL
  String _createDocumentId(String url) {
    return url
        .replaceAll(RegExp(r'[^\w\s-]'), '_') // Replace invalid chars with underscore
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .toLowerCase(); // Convert to lowercase
  }

  // Save a list of products to Firebase
  Future<void> saveProducts(List<Product> products) async {
    try {
      WriteBatch batch = _firestore.batch();
      int nextId = await _getNextProductId();

      for (var product in products) {
        String docId = _createDocumentId(product.url);
        DocumentReference docRef = _productsCollection.doc(docId);

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
          stockCount: 1 + (DateTime.now().millisecondsSinceEpoch % 150),
        );

        Map<String, dynamic> data = updatedProduct.toMap();
        batch.set(docRef, data, SetOptions(merge: true));
        nextId++;
      }

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
      final QuerySnapshot snapshot = await _productsCollection
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 1;
      }

      final highestId = (snapshot.docs.first.data() as Map<String, dynamic>)['id'] as int;
      return highestId + 1;
    } catch (e) {
      print('Error getting next product ID: $e');
      return 1;
    }
  }

  // Save featured products to Firebase
  Future<void> saveFeaturedProducts(List<Product> featuredProducts) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var product in featuredProducts) {
        String docId = _createDocumentId(product.url);
        DocumentReference docRef = _featuredProductsCollection.doc(docId);
        Map<String, dynamic> data = product.toMap();
        data['docId'] = docId;
        batch.set(docRef, data, SetOptions(merge: true));
      }

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
          .orderBy('rating', descending: true)
          .limit(4)
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
      DocumentSnapshot snapshot = await _categoriesCollection.doc('categories').get();

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

      QuerySnapshot snapshot = await _productsCollection
          .where('name', isGreaterThanOrEqualTo: category)
          .where('name', isLessThan: category + 'z')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return Product.fromFirebase(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting products by category from Firebase: $e');
      return [];
    }
  }
}
