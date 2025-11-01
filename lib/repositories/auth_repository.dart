import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // SIGN IN with email and password
  Future<User> signIn({required String emailOrPhone, required String password}) async {
    // For simplicity, sign in with email/password only.
    // Add phone number support if needed later.

    UserCredential cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: emailOrPhone.trim(),
      password: password.trim(),
    );
    return cred.user!;
  }

  // SIGN UP with email and password
  Future<User> signUp({required String email, required String password}) async {
    UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return cred.user!;
  }

  // SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // GET CURRENT USER
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // EMAIL VERIFICATION: Send Email Verification
  Future<void> sendEmailVerification(User user) async {
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

// Add phone sign-in and SMS verification logic later as required.
}