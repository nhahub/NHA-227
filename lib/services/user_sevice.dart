import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's name with detailed debugging
  Future<String> getUserName() async {
    print('🔍 Getting user name...'); // DEBUG
    
    final user = _auth.currentUser;
    if (user == null) {
      print('🔴 No user signed in'); // DEBUG
      return 'Guest';
    }

    print('🔵 User UID: ${user.uid}'); // DEBUG
    print('🔵 User email: ${user.email}'); // DEBUG
    print('🔵 Display name from Auth: ${user.displayName}'); // DEBUG

    // Try getting from display name first
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      print('✅ Found name in displayName: ${user.displayName}'); // DEBUG
      return user.displayName!;
    }

    // Fallback to Firestore
    try {
      print('🔵 Fetching from Firestore...'); // DEBUG
      final doc = await _firestore.collection('users').doc(user.uid).get();
      print('🔵 Document exists: ${doc.exists}'); // DEBUG
      print('🔵 Document data: ${doc.data()}'); // DEBUG
      
      if (doc.exists && doc.data() != null) {
        final name = doc.data()?['name'];
        print('✅ Found name in Firestore: $name'); // DEBUG
        return name ?? 'User';
      }
      print('🔴 No data found in Firestore'); // DEBUG
      return 'User';
    } catch (e) {
      print('🔴 Error getting user name from Firestore: $e'); // DEBUG
      return 'User';
    }
  }

  /// Get current user's email
  String getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  /// Get user photo URL
  String? getUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  /// Reload current user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}