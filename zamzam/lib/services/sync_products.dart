import 'package:flutter/foundation.dart';
import 'api_services.dart';
import 'product_firebase_service.dart';

class SyncProductsService {
  final ApiService _apiService = ApiService();
  final ProductFirebaseService _productFirebaseService =
      ProductFirebaseService();

  // Sync all products from API to Firebase
  Future<void> syncProductsToFirebase() async {
    try {
      debugPrint('Starting product synchronization...');

      // Fetch products from API
      final List<Product> products = await ApiService.fetchProducts();
      debugPrint('Fetched ${products.length} products from API');

      // Save products to Firebase
      await _productFirebaseService.saveProducts(products);
      debugPrint('Saved ${products.length} products to Firebase');

      // Fetch and save featured products
      final List<Product> featuredProducts =
          await ApiService.getFeaturedProducts();
      debugPrint(
          'Fetched ${featuredProducts.length} featured products from API');
      await _productFirebaseService.saveFeaturedProducts(featuredProducts);
      debugPrint('Saved featured products to Firebase');

      // Sync products by category
      for (String category in ApiService.productCategories) {
        if (category.toLowerCase() != 'all') {
          debugPrint('Syncing products for category: $category');
          await syncProductsByCategoryToFirebase(category);
        }
      }

      // Save categories
      await _productFirebaseService
          .saveCategories(ApiService.productCategories);
      debugPrint('Saved categories to Firebase');

      debugPrint('Products successfully synced to Firebase');
    } catch (e) {
      debugPrint('Error syncing products to Firebase: $e');
      throw Exception('Failed to sync products to Firebase: $e');
    }
  }

  // Sync only featured products
  Future<void> syncFeaturedProductsToFirebase() async {
    try {
      final List<Product> featuredProducts =
          await ApiService.getFeaturedProducts();
      await _productFirebaseService.saveFeaturedProducts(featuredProducts);
      debugPrint('Featured products successfully synced to Firebase');
    } catch (e) {
      debugPrint('Error syncing featured products to Firebase: $e');
      throw Exception('Failed to sync featured products to Firebase: $e');
    }
  }

  // Sync products by category
  Future<void> syncProductsByCategoryToFirebase(String category) async {
    try {
      final List<Product> categoryProducts =
          await ApiService.getProductsByCategory(category);
      await _productFirebaseService.saveProducts(categoryProducts);
      debugPrint(
          'Products for category $category successfully synced to Firebase');
    } catch (e) {
      debugPrint(
          'Error syncing products for category $category to Firebase: $e');
      throw Exception(
          'Failed to sync products for category $category to Firebase: $e');
    }
  }
}
