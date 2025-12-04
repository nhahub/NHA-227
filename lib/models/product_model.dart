import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String shortDescription; // Added
  final double price;
  final String currency; // Added
  final String imageUrl;
  final List<String>? imageUrls;
  final String category;
  final String? categoryId;
  final String sku; // Added
  final int stock;
  bool isFavorite;
  final bool isPopular;
  final List<String> searchKeywords;
  final List<String> tags; // Added

  // Text content
  final String overview;
  final String howToUse;

  // Rich Data
  final Map<String, dynamic> attributes; // Dosage, Form, Active Ingredient
  final double rating; // Extracted from Map
  final int reviewCount; // Extracted from Map

  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.shortDescription = '',
    required this.price,
    this.currency = 'EGP',
    required this.imageUrl,
    this.imageUrls,
    this.category = '',
    this.categoryId,
    this.sku = '',
    this.stock = 0,
    this.isFavorite = false,
    this.isPopular = false,
    this.searchKeywords = const [],
    this.tags = const [],
    this.overview = '',
    this.howToUse = '',
    this.attributes = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    double priceDouble = 0.0;
    final rawPrice = map['price'];
    if (rawPrice is int) priceDouble = rawPrice.toDouble();
    if (rawPrice is double) priceDouble = rawPrice;

    // Handle Rating Map { "avg": 4.5, "count": 100 }
    double avgRating = 0.0;
    int countRating = 0;
    if (map['rating'] is Map) {
      avgRating = (map['rating']['avg'] ?? 0).toDouble();
      countRating = (map['rating']['count'] ?? 0).toInt();
    }

    DateTime? created;
    if (map['createdAt'] != null) {
      final c = map['createdAt'];
      if (c is Timestamp) {
        created = c.toDate();
      } else if (c is String)
        created = DateTime.tryParse(c);
    }

    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      price: priceDouble,
      currency: map['currency'] ?? 'EGP',
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : null,
      category: map['category'] ?? '',
      categoryId: map['categoryId'],
      sku: map['sku'] ?? '',
      stock: (map['stock'] is int) ? map['stock'] as int : 0,
      isFavorite: false, // Managed locally
      isPopular: map['isPopular'] ?? false,
      searchKeywords: map['searchKeywords'] != null
          ? List<String>.from(map['searchKeywords'])
          : [],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      overview: map['overview'] ?? '',
      howToUse: map['howToUse'] ?? '',
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'])
          : {},
      rating: avgRating,
      reviewCount: countRating,
      createdAt: created,
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(data, doc.id);
  }
}
