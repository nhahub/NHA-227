import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

String? _verificationId; // Saved during phone verification

// ---------------------------------------------------------------------------
// PUBLIC: UID stream/getter + sign-in navigation hooks (added for Cart/Orders)
// ---------------------------------------------------------------------------

// Emits the current UID when signed in, or null when signed out.
Stream<String?> uidChanges() =>
_firebaseAuth.authStateChanges().map((u) => u?.uid);

// Current UID if signed in; otherwise null.
String? get currentUid => _firebaseAuth.currentUser?.uid;

// Ensure the user is signed in (used by Checkout in Cart).
// Navigates to your sign-in flow if needed. Returns UID on success, or null.
Future<String?> ensureSignedIn(BuildContext context) async {
final uid = _firebaseAuth.currentUser?.uid;
if (uid != null) return uid;


// Adjust route name if your app uses a different one.
final result = await Navigator.of(context).pushNamed<String>('/signin');

// Either the sign-in screen returns a UID or we read it after Firebase updates.
return result ?? _firebaseAuth.currentUser?.uid;
}

// Directly open the sign-in UI (used by “Sign in to view orders” CTA).
void openSignInScreen(BuildContext context) {
Navigator.of(context).pushNamed('/signin');
}

// ---------------------------------------------------------------------------
// EMAIL/PASSWORD SIGN-IN & SIGN-UP
// ---------------------------------------------------------------------------

Future signIn({
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

Future signUp({
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

Future sendPasswordResetEmail(String email) async {
try {
await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
} on FirebaseAuthException catch (e) {
throw Exception(_formatFirebaseError(e));
}
}

Future signOut() async {
await _firebaseAuth.signOut();
await _googleSignIn.signOut();
}

User? getCurrentUser() => _firebaseAuth.currentUser;

// ---------------------------------------------------------------------------
// PHONE AUTHENTICATION
// ---------------------------------------------------------------------------

Future verifyPhoneNumber({
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
log('Verification failed: {e.message}'); onVerificationFailed(_formatFirebaseError(e)); }, codeSent: (String verificationId, int? resendToken) { _verificationId = verificationId; log('Code sent: verificationId');
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

Future signInWithSmsCode(String smsCode) async {
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

Future sendEmailVerificationCode(String email) async {
// TODO: connect to your backend / Cloud Function
await Future.delayed(const Duration(seconds: 1));
log('Email verification code sent to $email (simulation)');
}

Future verifyEmailCode({
required String email,
required String code,
}) async {
// TODO: Replace with actual backend validation.
await Future.delayed(const Duration(seconds: 1));
return code == '12345';
}

// ---------------------------------------------------------------------------
// GOOGLE SIGN-IN
// ---------------------------------------------------------------------------

Future signInWithGoogle() async {
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
