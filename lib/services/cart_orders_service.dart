import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class CartOrdersService {
  CartOrdersService._();
  static final CartOrdersService instance = CartOrdersService._();

final FirebaseFirestore _db = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

// Ensure a signed-in user exists
String get _uid {
final user = _auth.currentUser;
if (user == null) {
throw StateError('No logged-in user. Please sign in first.');
}
return user.uid;
}

// Collections
CollectionReference<Map<String, dynamic>> _cartCol(String uid) =>
_db.collection('users').doc(uid).collection('cart');

CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
_db.collection('users').doc(uid).collection('orders');

// --------------------
// CART
// --------------------

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

Future<List> getCartOnce() async {
final uid = _uid;
final snap = await _cartCol(uid).get();
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
}

Future addOrIncItem(CartItem item) async {
final uid = _uid;
final ref = _cartCol(uid).doc(item.productId);
await _db.runTransaction((tx) async {
final snap = await tx.get(ref);
if (snap.exists) {
final current =
((snap.data() as Map<String, dynamic>)['qty'] ?? 1) as int;
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

// --------------------
// ORDERS
// --------------------

// Stream of orders with their items subcollection
Stream<List> watchOrders() {
final uid = _uid;
return _ordersCol(uid)
.orderBy('createdAt', descending: true)
.snapshots()
.asyncMap((ordersSnap) async {
final List result = [];
for (final doc in ordersSnap.docs) {
// fetch items subcollection
final itemsSnap = await doc.reference.collection('items').get();
final items = itemsSnap.docs
.map((d) => OrderItem.fromMap(d.data()))
.toList();

    result.add(
      OrderModel.fromMap(
        id: doc.id,
        map: doc.data(),
        items: items,
      ),
    );
  }
  return result;
});
}

Future<OrderModel?> getOrderById(String orderId) async {
final uid = _uid;
final doc = await _ordersCol(uid).doc(orderId).get();
if (!doc.exists) return null;

final itemsSnap = await doc.reference.collection('items').get();
final items = itemsSnap.docs
    .map((d) => OrderItem.fromMap(d.data()))
    .toList();

return OrderModel.fromMap(
  id: doc.id,
  map: doc.data()!,
  items: items,
);
}

// Places an order using current cart.
// Writes metadata to order doc and each product to orders/{id}/items/{productId}.
Future placeOrderFromCart({
double shipping = 20,
String status = 'In Process',
String? paymentMethodId,
}) async {
final uid = _uid;

// Ensure user doc exists
await _ensureUserDoc();

// Read cart
final cartSnap = await _cartCol(uid).get();
if (cartSnap.docs.isEmpty) {
  throw StateError('Cart is empty');
}

// Build items
final items = cartSnap.docs.map((d) {
  final m = d.data();
  return OrderItem(
    productId: m['productId'] ?? d.id,
    title: m['title'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    price: (m['price'] ?? 0).toDouble(),
    qty: (m['qty'] ?? 1) as int,
  );
}).toList();

final subtotal = _computeSubtotal(items);
final totalQty = items.fold<int>(0, (s, e) => s + e.qty);
final itemsCount = items.length;
final total = subtotal + (items.isEmpty ? 0 : shipping);

// Prepare batch: create order, write items, clear cart
final orderRef = _ordersCol(uid).doc();
final batch = _db.batch();

final orderData = <String, dynamic>{
  'userId': uid,
  'subtotal': subtotal,
  'shipping': shipping,
  'total': total,
  'itemsCount': itemsCount,
  'totalQty': totalQty,
  'status': status,
  'createdAt': FieldValue.serverTimestamp(),
};
if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
  orderData['paymentMethodId'] = paymentMethodId;
}

// Order doc (no items array)
batch.set(orderRef, orderData);

// Items subcollection
final itemsCol = orderRef.collection('items');
for (final it in items) {
  batch.set(itemsCol.doc(it.productId), it.toMap());
}

// Clear cart
for (final d in cartSnap.docs) {
  batch.delete(d.reference);
}

// Commit
await batch.commit();
return orderRef.id;
}

double _computeSubtotal(List items) {
return items.fold(0.0, (sum, i) => sum + (i.price * i.qty));
}

Future _ensureUserDoc() async {
final uid = _uid;
final userRef = _db.collection('users').doc(uid);
await userRef.set(
{'updatedAt': FieldValue.serverTimestamp()},
SetOptions(merge: true),
);
}

Future wasRecentOrderCreated({Duration window = const Duration(seconds: 10)}) async {
final uid = _uid;
final now = DateTime.now();
final since = Timestamp.fromDate(now.subtract(window));
final q = await _ordersCol(uid)
.where('createdAt', isGreaterThanOrEqualTo: since)
.limit(1)
.get();
return q.docs.isNotEmpty;
}
}