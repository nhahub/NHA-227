import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(Duration(seconds: 2)); // simulate loading
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      context.go('/home');  // route to your home after sign in
    } else {
      context.go('/signin'); // route to sign in
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/medilink_logo.png', width: 200), // your logo asset
      ),
    );
  }
}