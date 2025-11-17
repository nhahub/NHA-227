import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:medilink_app/screens/auth/phone_sign_in_screen.dart';
import 'package:medilink_app/screens/cart/cart_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/find_account_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/auth/home_screen.dart';
import 'screens/auth/password_reset_confirmation_screen.dart';
/// Global router configuration for the app.
/// Handles navigation and parameter passing cleanly.
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),

    GoRoute(
      path: '/signin',
      builder: (context, state) => SignInScreen(),
    ),

    GoRoute(
      path: '/signup',
      builder: (context, state) => SignUpScreen(),
    ),

    GoRoute(
      path: '/forgot_password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),

    GoRoute(
      path: '/forgot_password_email',
      builder: (context, state) => FindAccountScreen(byMobile: false),
    ),

    GoRoute(
      path: '/find_account_mobile',
      builder: (context, state) => FindAccountScreen(byMobile: true),
    ),

    GoRoute(
      path: '/find_account_email',
      builder: (context, state) => FindAccountScreen(byMobile: false),
    ),

    GoRoute(
      path: '/verify_code',
      builder: (context, state) {
        // The 'isSms' flag indicates if it's SMS or email verification
        final bool isSms = state.uri.queryParameters['isSms'] == 'true';
        return VerifyCodeScreen(isSmsVerification: isSms);
      },
    ),

    GoRoute(
      path: '/home',
      builder: (context, state) => HomeScreen(),
    ),
    
    GoRoute(
      path: '/password_reset_sent',
      builder: (context, state) => const PasswordResetConfirmationScreen(),
    ),
    GoRoute(
      path: '/phone_sign_in',
      builder: (context, state) => const PhoneSignInScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
  ],
);