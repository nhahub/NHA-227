import 'package:flutter/foundation.dart';

class CartItem {
final String id; // Firestore doc id (or same as productId in cart)
final String productId; // Product identifier
final String title; // Product title
final String description; // Short description (optional in writes)
final String imageUrl; // Asset or network URL
final double price; // Unit price
int qty; // Quantity (mutable for local changes if needed)

CartItem({
required this.id,
required this.productId,
required this.title,
required this.description,
required this.imageUrl,
required this.price,
this.qty = 1,
});

double get lineTotal => price * qty;

// Serialization helpers (used if you ever want to write CartItem directly)
Map<String, dynamic> toMap() {
return {
'productId': productId,
'title': title,
'description': description,
'imageUrl': imageUrl,
'price': price,
'qty': qty,
};
}

factory CartItem.fromMap(String id, Map<String, dynamic> map) {
return CartItem(
id: id,
productId: map['productId'] as String? ?? id,
title: map['title'] as String? ?? '',
description: map['description'] as String? ?? '',
imageUrl: map['imageUrl'] as String? ?? '',
price: (map['price'] ?? 0).toDouble(),
qty: (map['qty'] ?? 1) as int,
);
}

CartItem copyWith({
String? id,
String? productId,
String? title,
String? description,
String? imageUrl,
double? price,
int? qty,
}) {
return CartItem(
id: id ?? this.id,
productId: productId ?? this.productId,
title: title ?? this.title,
description: description ?? this.description,
imageUrl: imageUrl ?? this.imageUrl,
price: price ?? this.price,
qty: qty ?? this.qty,
);
}

@override
String toString() =>
'CartItem(id: $id, productId: $productId, title: $title, price: $price, qty: $qty)';
}