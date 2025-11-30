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
productId: (map['productId'] ?? '') as String,
title: (map['title'] ?? '') as String,
imageUrl: (map['imageUrl'] ?? '') as String,
price: (map['price'] ?? 0).toDouble(),
qty: (map['qty'] ?? 0) as int,
);
}

class OrderModel {
final String id;
final String userId;
final List<OrderItem> items;

final double subtotal;
final double shipping;
final double total;

final int itemsCount; // distinct products
final int totalQty; // sum of qty across products

// Delivered | Canceled | In Process
final String status;

final DateTime? createdAt;

OrderModel({
required this.id,
required this.userId,
required this.items,
required this.subtotal,
required this.shipping,
required this.total,
required this.itemsCount,
required this.totalQty,
required this.status,
required this.createdAt,
});

// Order doc data only (not items subcollection)
Map<String, dynamic> toMap() => {
'userId': userId,
'subtotal': subtotal,
'shipping': shipping,
'total': total,
'itemsCount': itemsCount,
'totalQty': totalQty,
'status': status,
'createdAt': createdAt?.millisecondsSinceEpoch,
};

// Build from the order document map plus a list of already-parsed items.
factory OrderModel.fromMap({
required String id,
required Map<String, dynamic> map,
required List<OrderItem> items,
}) {
return OrderModel(
id: id,
userId: (map['userId'] ?? '') as String,
items: items,
subtotal: (map['subtotal'] ?? 0).toDouble(),
shipping: (map['shipping'] ?? 0).toDouble(),
total: (map['total'] ?? 0).toDouble(),
itemsCount: (map['itemsCount'] ?? items.length) as int,
totalQty: (map['totalQty'] ?? _calcTotalQty(items)) as int,
status: (map['status'] ?? 'In Process') as String,
createdAt: _parseDate(map['createdAt']),
);
}

static int _calcTotalQty(List<OrderItem> items) =>
items.fold<int>(0, (int s, OrderItem e) => s + e.qty);

// Accepts Timestamp (from Firestore), int (ms), or String ISO; returns DateTime?
static DateTime? _parseDate(dynamic v) {
if (v == null) return null;
try {
if (kIsWeb) {
// On web you usually get a JS date -> Timestamp; keep generic handling below
}
// Firestore Timestamp has a toDate() method; avoid hard import
if (v is Object && (v).toString().contains('Timestamp')) {
// Try to call toDate via dynamic
final toDate = (v as dynamic).toDate;
if (toDate is Function) return toDate() as DateTime;
}
} catch (_) {}
if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
if (v is String) return DateTime.tryParse(v);
if (v is DateTime) return v;
return null;
}
}