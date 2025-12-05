import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/models/category_model.dart';
import 'package:medilink_app/models/pharmacy_model.dart';

class ProductRepository extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Private Lists
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Pharmacy> _pharmacies = [];

  // --- NEW: Loading State for Skeleton ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Error Handling
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _productsSub;
  StreamSubscription<QuerySnapshot>? _categoriesSub;
  StreamSubscription<QuerySnapshot>? _pharmaciesSub;

  ProductRepository() {
    _initListeners();
  }

  void _initListeners() {
    // 1. Listen to Products
    _productsSub = _db
        .collection('products')
        .where('published', isEqualTo: true)
        .snapshots()
        .listen(
      (snap) {
        final favMap = {for (var p in _products) p.id: p.isFavorite};
        _products = snap.docs.map((doc) {
          final prod = Product.fromFirestore(doc);
          prod.isFavorite = favMap[prod.id] ?? false;
          return prod;
        }).toList();

        // --- NEW: Stop loading when data arrives ---
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _error = _formatError(err);
        _isLoading = false; // Stop loading even on error
        notifyListeners();
      },
    );

    // 2. Listen to Categories
    _categoriesSub = _db.collection('categories').snapshots().listen(
      (snap) {
        _categories =
            snap.docs.map((doc) => Category.fromFirestore(doc)).toList();
        _categories.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        notifyListeners();
      },
      onError: (err) {
        _error = _formatError(err);
        notifyListeners();
      },
    );

    // 3. Listen to Pharmacies
    _pharmaciesSub = _db.collection('pharmacies').snapshots().listen(
      (snap) {
        _pharmacies =
            snap.docs.map((doc) => Pharmacy.fromFirestore(doc)).toList();
        notifyListeners();
      },
      onError: (err) {
        _error = _formatError(err);
        notifyListeners();
      },
    );
  }

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Pharmacy> get pharmacies => List.unmodifiable(_pharmacies);

  List<Product> get favoriteProducts =>
      _products.where((p) => p.isFavorite).toList();

  List<Product> get popularProducts =>
      _products.where((p) => p.isPopular).toList();

  void toggleFavorite(String productId) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].isFavorite = !_products[index].isFavorite;
      notifyListeners();
    }
  }

  String _formatError(Object err) {
    final msg = err.toString();
    if (msg.contains('permission-denied')) {
      return 'Permission denied. Check Firestore rules.';
    }
    return msg;
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return [];
    return _products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.searchKeywords.contains(query.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _pharmaciesSub?.cancel();
    super.dispose();
  }

  void refresh() {
    _error = null;
    _isLoading = true; // Reset loading state on retry
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _pharmaciesSub?.cancel();
    _initListeners();
    notifyListeners();
  }
  // Add to ProductRepository class
bool isFavoriteById(String productId) {
  return products.any((p) => p.id == productId && p.isFavorite);
}

void toggleFavoriteById(String productId) {
  final product = products.firstWhere(
    (p) => p.id == productId,
    orElse: () => products.first, // fallback
  );
  if (product.id == productId) {
    toggleFavorite(productId);
  }
}
}