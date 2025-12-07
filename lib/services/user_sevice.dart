import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Guest';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()!['name'];
        return name ?? 'User';
      }
      return 'User';
    } catch (_) {
      return 'User';
    }
  }

  String getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    await user.updateDisplayName(name);
    if (email.isNotEmpty && email != user.email) {
      // Firebase Auth v6 removed updateEmail; this sends a verification to apply the change.
      await user.verifyBeforeUpdateEmail(email);
    }
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
    }, SetOptions(merge: true));
  }

  Future<String?> getPhone() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return doc.data()?['phone'] as String?;
  }

  Future<bool> getNotificationsEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return true;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('notificationsEnabled')) {
      return doc.data()!['notificationsEnabled'] == true;
    }
    return true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'notificationsEnabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<String> getLanguage() async {
    final user = _auth.currentUser;
    if (user == null) return 'en';
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('language')) {
      return (doc.data()!['language'] as String?) ?? 'en';
    }
    return 'en';
  }

  Future<void> setLanguage(String code) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'language': code,
    }, SetOptions(merge: true));
  }

  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
