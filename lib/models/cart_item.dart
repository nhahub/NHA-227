import 'package:flutter/foundation.dart';

class CartItem {
final String id;
final String productId;
final String title;
final String description;
final String imageUrl;
final double price;
int qty;

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
}