import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class CartOrdersService {
  CartOrdersService._();
  static final instance = CartOrdersService._();

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

// Paths: users/{uid}/cart/{productId}, users/{uid}/orders/{orderId}
String get _uid {
final user = _auth.currentUser;
if (user == null) {
throw StateError('No logged-in user. Make sure FirebaseAuth is set.');
}
return user.uid;
}

CollectionReference<Map<String, dynamic>> _cartCol(String uid) =>
_db.collection('users').doc(uid).collection('cart');

CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
_db.collection('users').doc(uid).collection('orders');

// CART

Stream<List> watchCart() {
final uid = _uid;
return _cartCol(uid).snapshots().map((snap) {
return snap.docs.map((d) {
final data = d.data();
return CartItem(
id: d.id,
productId: data['productId'] ?? d.id,
title: data['title'] ?? '',
description: data['description'] ?? '',
imageUrl: data['imageUrl'] ?? '',
price: (data['price'] ?? 0).toDouble(),
qty: (data['qty'] ?? 1) as int,
);
}).toList();
});
}

Future addOrIncItem(CartItem item) async {
final uid = _uid;
final ref = _cartCol(uid).doc(item.productId);
await _db.runTransaction((tx) async {
final snap = await tx.get(ref);
if (snap.exists) {
final current = (snap.data()!['qty'] ?? 1) as int;
tx.update(ref, {'qty': current + item.qty});
} else {
tx.set(ref, {
'productId': item.productId,
'title': item.title,
'description': item.description,
'imageUrl': item.imageUrl,
'price': item.price,
'qty': item.qty,
'createdAt': FieldValue.serverTimestamp(),
});
}
});
}

Future updateQty(String productId, int qty) async {
final uid = _uid;
if (qty <= 0) {
await removeItem(productId);
return;
}
await _cartCol(uid).doc(productId).update({'qty': qty});
}

Future removeItem(String productId) async {
final uid = _uid;
await _cartCol(uid).doc(productId).delete();
}

Future clearCart() async {
final uid = _uid;
final batch = _db.batch();
final docs = await _cartCol(uid).get();
for (final d in docs.docs) {
batch.delete(d.reference);
}
await batch.commit();
}

// ORDERS

Stream<List> watchOrders() {
final uid = _uid;
return _ordersCol(uid)
.orderBy('createdAt', descending: true)
.snapshots()
.map((snap) => snap.docs.map((d) {
final data = d.data();
return OrderModel(
id: d.id,
userId: uid,
items: (data['items'] as List? ?? [])
.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
.toList(),
subtotal: (data['subtotal'] ?? 0).toDouble(),
shipping: (data['shipping'] ?? 0).toDouble(),
total: (data['total'] ?? 0).toDouble(),
status: data['status'] ?? 'In Process',
createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
);
}).toList());
}

Future<OrderModel?> getOrderById(String orderId) async {
final uid = _uid;
final doc = await _ordersCol(uid).doc(orderId).get();
if (!doc.exists) return null;
final data = doc.data()!;
return OrderModel(
id: doc.id,
userId: uid,
items: (data['items'] as List? ?? [])
.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
.toList(),
subtotal: (data['subtotal'] ?? 0).toDouble(),
shipping: (data['shipping'] ?? 0).toDouble(),
total: (data['total'] ?? 0).toDouble(),
status: data['status'] ?? 'In Process',
createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
);
}

// Places an order using current cart. Returns orderId.
Future placeOrderFromCart({
double shipping = 20,
String status = 'In Process',
}) async {
final uid = _uid;
final cartSnap = await _cartCol(uid).get();
if (cartSnap.docs.isEmpty) throw StateError('Cart is empty');
final items = cartSnap.docs.map((d) {
  final data = d.data();
  return OrderItem(
    productId: data['productId'] ?? d.id,
    title: data['title'] ?? '',
    imageUrl: data['imageUrl'] ?? '',
    price: (data['price'] ?? 0).toDouble(),
    qty: (data['qty'] ?? 1) as int,
  );
}).toList();

final subtotal =
    items.fold<double>(0, (sum, e) => sum + (e.price * e.qty));
final total = subtotal + shipping;

final orderRef = _ordersCol(uid).doc();

await _db.runTransaction((tx) async {
  tx.set(orderRef, {
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'shipping': shipping,
    'total': total,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // clear cart
  for (final d in cartSnap.docs) {
    tx.delete(d.reference);
  }
});

return orderRef.id;
}
}