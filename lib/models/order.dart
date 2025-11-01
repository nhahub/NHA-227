import 'package:flutter/foundation.dart';

class OrderItem {
final String productId;
final String title;
final String imageUrl;
final double price;
final int qty;

OrderItem({
required this.productId,
required this.title,
required this.imageUrl,
required this.price,
required this.qty,
});

Map<String, dynamic> toMap() => {
'productId': productId,
'title': title,
'imageUrl': imageUrl,
'price': price,
'qty': qty,
};

factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
productId: map['productId'] ?? '',
title: map['title'] ?? '',
imageUrl: map['imageUrl'] ?? '',
price: (map['price'] ?? 0).toDouble(),
qty: (map['qty'] ?? 1) as int,
);
}

class OrderModel {
final String id;
final String userId;
final List items;
final double subtotal;
final double shipping;
final double total;
final String status; // Delivered | Canceled | In Process
final DateTime? createdAt;

OrderModel({
required this.id,
required this.userId,
required this.items,
required this.subtotal,
required this.shipping,
required this.total,
required this.status,
required this.createdAt,
});
}