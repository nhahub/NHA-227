import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
PaymentService();
  static final instance = PaymentService();

final _db = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

String get _uid {
final u = _auth.currentUser;
if (u == null) {
throw StateError('No logged-in user. Please sign in first.');
}
return u.uid;
}

CollectionReference<Map<String, dynamic>> _pmCol(String uid) =>
_db.collection('users').doc(uid).collection('paymentMethods');

Future hasAnyPaymentMethod() async {
final uid = _uid;
final snap = await _pmCol(uid).limit(1).get();
return snap.docs.isNotEmpty;
}

Future saveCard({
required String holderName,
required String cardNumber, // we only store last4 + brand
required String exp, // MM/YY or MM/YYYY
}) async {
final uid = _uid;

final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
final brand = _detectBrand(digits);

final parts = exp.split('/');
final mm = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '';
final rawYear = parts.length > 1 ? parts[1] : '';
final yyyy = rawYear.length == 2 ? '20$rawYear' : rawYear;

final ref = _pmCol(uid).doc();
await ref.set({
  'type': 'card',
  'holderName': holderName,
  'brand': brand,
  'last4': last4,
  'expMonth': mm,
  'expYear': yyyy,
  'createdAt': FieldValue.serverTimestamp(),
});
return ref.id;
}

Future savePayPal() async {
final uid = _uid;
final ref = _pmCol(uid).doc();
await ref.set({
'type': 'paypal',
'createdAt': FieldValue.serverTimestamp(),
});
return ref.id;
}

String _detectBrand(String digits) {
if (digits.startsWith('4')) return 'Visa';
if (RegExp(r'^(5[1-5])').hasMatch(digits)) return 'Mastercard';
if (RegExp(r'^(3[47])').hasMatch(digits)) return 'American Express';
if (RegExp(r'^(6(?:011|5))').hasMatch(digits)) return 'Discover';
return 'Card';
}
}

