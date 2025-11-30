import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged-in user. Please sign in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _pmCol(String uid) =>
      _db.collection('users').doc(uid).collection('paymentMethods');

  // Check if user has at least one saved payment method
  Future hasAnyPaymentMethod() async {
    final uid = _uid;
    final snap = await _pmCol(uid).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  // Save a credit card (safe fields only). Returns document id.
  // cardNumber: full entry from the form; only last4 + brand are stored.
  // exp: "MM/YY"
  Future saveCard({
    required String holderName,
    required String cardNumber,
    required String exp,
    bool saved = true,
  }) async {
    final uid = _uid;

    final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
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
      'saved': saved, // reflects the checkbox
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  // Save a PayPal method. Returns document id.
  Future savePayPal({required String email, bool saved = true}) async {
    final uid = _uid;

    final ref = _pmCol(uid).doc();
    await ref.set({
      'type': 'paypal',
      'email': email,
      'saved': saved,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  // Optional: stream all methods for the user (useful for a "Payment Methods" page)
  Stream<List<Map<String, dynamic>>> watchPaymentMethods() {
    final uid = _uid;
    return _pmCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // Optional: get all methods once
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final uid = _uid;
    final snap = await _pmCol(uid).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // Optional: delete a method by id
  Future deletePaymentMethod(String id) async {
    final uid = _uid;
    await _pmCol(uid).doc(id).delete();
  }

  // Brand detection (basic)
  String _detectBrand(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5])').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^(3[47])').hasMatch(digits)) return 'American Express';
    if (RegExp(r'^(6(?:011|5))').hasMatch(digits)) return 'Discover';
    return 'Card';
  }
}
