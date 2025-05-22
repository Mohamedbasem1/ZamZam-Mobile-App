import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/api_services.dart' show Product;

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  factory FavoriteService() {
    return _instance;
  }

  FavoriteService._internal();

  // Add product to favorites
  Future<void> toggleFavorite(Product product) async {
    try {
      // Check login status
      if (!_firebaseService.isLoggedIn) {
        throw Exception('User must be logged in to manage favorites');
      }

      // Validate product data
      if (product.url.isEmpty) {
        throw Exception('Invalid product data: URL is required');
      }

      String userId = _firebaseService.currentUser!.uid;
      
      // More robust product ID generation
      String productId;
      if (product.docId != null && product.docId!.isNotEmpty) {
        productId = product.docId!;
      } else if (product.id != 0) {
        productId = product.id.toString();
      } else {
        // Fallback to URL-based ID with better sanitization
        productId = product.url
            .replaceAll(RegExp(r'[^\w\s-]'), '_')
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase();
      }

      // Reference to the user's favorites document
      DocumentReference favoriteRef = _firestore
          .collection('favorites')
          .doc(userId)
          .collection('user_favorites')
          .doc(productId);

      try {
        // Check if the product is already in favorites
        DocumentSnapshot doc = await favoriteRef.get();

        if (doc.exists) {
          // Remove from favorites
          await favoriteRef.delete();
        } else {
          // Validate required product data
          if (product.name.isEmpty) {
            throw Exception('Invalid product data: Name is required');
          }

          // Add to favorites with error checking
          Map<String, dynamic> favoriteData = {
            'productId': productId,
            'userId': userId,
            'name': product.name,
            'price': product.price,
            'image': product.image,
            'url': product.url,
            'nameUrl': product.nameUrl,
            'rating': product.rating,
            'ratingCount': product.ratingCount,
            'isFeatured': product.isFeatured,
            'id': product.id,
            'stockCount': product.stockCount,
            'addedAt': FieldValue.serverTimestamp(),
          };

          // Ensure all values are not null
          favoriteData.forEach((key, value) {
            if (value == null) {
              favoriteData[key] = ''; // or 0 for numeric fields
            }
          });

          await favoriteRef.set(favoriteData);
        }
      } catch (firestoreError) {
        print('Firestore operation error: $firestoreError');
        throw Exception('Failed to update favorites in database: $firestoreError');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Failed to update favorites: ${e.toString()}');
    }
  }

  // Check if a product is in favorites
  Future<bool> isFavorite(String productUrl) async {
    try {
      if (!_firebaseService.isLoggedIn) return false;

      String userId = _firebaseService.currentUser!.uid;
      String productId = productUrl.replaceAll(RegExp(r'[^\w\s-]'), '_');
      
      DocumentSnapshot doc = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('user_favorites')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorite products for current user
  Future<List<Product>> getFavoriteProducts() async {
    try {
      if (!_firebaseService.isLoggedIn) return [];

      String userId = _firebaseService.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('user_favorites')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Product(
          name: data['name'] ?? '',
          price: data['price'] ?? '',
          image: data['image'] ?? '',
          url: data['url'] ?? '',
          nameUrl: data['nameUrl'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          ratingCount: data['ratingCount'] ?? 0,
          isFeatured: data['isFeatured'] ?? false,
          docId: doc.id,
          id: data['id'] ?? 0,
          stockCount: data['stockCount'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error getting favorite products: $e');
      return [];
    }
  }

  // Stream of favorite products for real-time updates
  Stream<List<Product>> getFavoriteProductsStream() {
    if (!_firebaseService.isLoggedIn) {
      return Stream.value([]);
    }

    String userId = _firebaseService.currentUser!.uid;
    return _firestore
        .collection('favorites')
        .doc(userId)
        .collection('user_favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Product(
          name: data['name'] ?? '',
          price: data['price'] ?? '',
          image: data['image'] ?? '',
          url: data['url'] ?? '',
          nameUrl: data['nameUrl'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          ratingCount: data['ratingCount'] ?? 0,
          isFeatured: data['isFeatured'] ?? false,
          docId: doc.id,
          id: data['id'] ?? 0,
          stockCount: data['stockCount'] ?? 0,
        );
      }).toList();
    });
  }
} 