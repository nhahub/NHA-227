import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _verificationId; // Saved during phone verification

  // ---------------------------------------------------------------------------
  // EMAIL/PASSWORD SIGN-IN & SIGN-UP
  // ---------------------------------------------------------------------------

  Future<User> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailOrPhone.trim(),
        password: password.trim(),
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_formatFirebaseError(e));
    } catch (e) {
      throw Exception('Unexpected sign in error: $e');
    }
  }

  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_formatFirebaseError(e));
    } catch (e) {
      throw Exception('Unexpected sign up error: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_formatFirebaseError(e));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  User? getCurrentUser() => _firebaseAuth.currentUser;

  // ---------------------------------------------------------------------------
  // PHONE AUTHENTICATION
  // ---------------------------------------------------------------------------

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(String errorMsg) onVerificationFailed,
    required Function(String verificationId) onTimeout,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          log('Auto verification completed');
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          log('Verification failed: ${e.message}');
          onVerificationFailed(_formatFirebaseError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          log('Code sent: $verificationId');
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          onTimeout(verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_formatFirebaseError(e));
    }
  }

  Future<UserCredential> signInWithSmsCode(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('Verification ID is null. Please request a new code.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode.trim(),
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // ---------------------------------------------------------------------------
  // EMAIL VERIFICATION CODE LOGIC (backend or local simulation)
  // ---------------------------------------------------------------------------

  /// Send 5-digit code to email (simulation).
  /// In production, call your backend to handle sending email.
  Future<void> sendEmailVerificationCode(String email) async {
    // TODO: connect to your backend / Cloud Function
    // Temporary simulated delay
    await Future.delayed(const Duration(seconds: 1));
    log('Email verification code sent to $email (simulation)');
  }

  /// Verify code with backend simulation.
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    // TODO: Replace this logic with actual backend validation.
    await Future.delayed(const Duration(seconds: 1));

    // Simple demo: if code == "12345", treat as correct
    if (code == '12345') {
      log('Email verification code validated for $email');
      return true;
    } else {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------------------------

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_formatFirebaseError(e));
    } catch (e) {
      throw Exception('Unexpected Google sign in error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UTILITY: ERROR MAPPING
  // ---------------------------------------------------------------------------

  String _formatFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'User not found. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already associated with an account.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';
      default:
        return e.message ?? 'Unknown Firebase error occurred.';
    }
  }
}