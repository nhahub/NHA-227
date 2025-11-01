import 'package:go_router/go_router.dart';
import 'package:medilink_app/screens/auth/home_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verify_code_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    GoRoute(path: '/signin', builder: (context, state) => SignInScreen()),
    GoRoute(path: '/signup', builder: (context, state) => SignUpScreen()),
    GoRoute(path: '/forgot_password', builder: (context, state) => ForgotPasswordScreen()),
    GoRoute(
      path: '/verify_code',
      builder: (context, state) {
        final verificationId = state.extra as String? ?? '';
        return VerifyCodeScreen(/* pass params if needed */);
      },
    ),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),  // Add this line
  ],
);