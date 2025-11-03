import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';

Future main() async {
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// Ensure we have a user (anonymous ok for dev)
final auth = FirebaseAuth.instance;
if (auth.currentUser == null) {
await auth.signInAnonymously();
}

// Ensure parent user doc exists
await _ensureUserDoc(auth.currentUser!.uid);

  // 4) Debug prints (confirm project/uid)
  debugPrint('Firebase ProjectId: ${DefaultFirebaseOptions.currentPlatform.projectId}');
  debugPrint('FirebaseAppId: ${DefaultFirebaseOptions.currentPlatform.appId}');
  final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
  debugPrint('Firebase ApiKey: ${apiKey.substring(0, 6)}...');
  debugPrint('AuthUID: ${auth.currentUser?.uid}');

  runApp(const MedlinkApp());
}

Future _ensureUserDoc(String uid) async {
final ref = FirebaseFirestore.instance.collection('users').doc(uid);
await ref.set(
{
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
},
SetOptions(merge: true),
);
}

class MedlinkApp extends StatelessWidget {
const MedlinkApp({super.key});

@override
Widget build(BuildContext context) {
const brandBlue = Color(0xFF0E5AA6);
return MaterialApp(
title: 'Medlink Pharmacy',
debugShowCheckedModeBanner: false,
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
scaffoldBackgroundColor: const Color(0xFFF2F7FB),
useMaterial3: false,
),
initialRoute: AppRoutes.cart,
routes: AppRoutes.routes, // simple routes
onGenerateRoute: AppRoutes.onGenerateRoute, // enables fade + fallback
);
}
}