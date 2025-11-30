import 'package:go_router/go_router.dart';
import 'package:medilink_app/models/category_model.dart';
import 'package:medilink_app/models/pharmacy_model.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/screens/active_ingredient.dart';
import 'package:medilink_app/screens/auth/phone_sign_in_screen.dart';
import 'package:medilink_app/screens/cart/cart_screen.dart';
import 'package:medilink_app/screens/cart/checkout_screen.dart';
import 'package:medilink_app/screens/categories_screen.dart';
import 'package:medilink_app/screens/category_products_screen.dart';
import 'package:medilink_app/screens/favorites_screen.dart';
import 'package:medilink_app/screens/home_screen.dart';
import 'package:medilink_app/screens/orders/last_order_screen.dart';
import 'package:medilink_app/screens/orders/orders_screen.dart';
import 'package:medilink_app/screens/main_shell.dart';
import 'package:medilink_app/screens/pharmacies_screen.dart';
import 'package:medilink_app/screens/pharmacy_detail_screen.dart';
import 'package:medilink_app/screens/popular_screen.dart';
import 'package:medilink_app/screens/product_detail_screen.dart';
import 'package:medilink_app/screens/related_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/find_account_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/auth/password_reset_confirmation_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Auth Routes ---
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(path: '/forgot_password', builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/phone_sign_in', builder: (context, state) => const PhoneSignInScreen()),
    GoRoute(path: '/password_reset_sent', builder: (context, state) => const PasswordResetConfirmationScreen()),
    GoRoute(
      path: '/verify_code',
      builder: (context, state) {
        final bool isSms = state.uri.queryParameters['isSms'] == 'true';
        return VerifyCodeScreen(isSmsVerification: isSms);
      },
    ),

    // --- Main Shell (Bottom Nav) ---
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home', 
          builder: (c, s) => const HomeScreen(),
          routes: [
            // Nested routes for Home Tab
            GoRoute(
              path: 'categories',
              builder: (context, state) => const CategoriesScreen(),
            ),
            GoRoute(
              path: 'pharmacies',
              builder: (context, state) => const PharmaciesScreen(),
            ),
            GoRoute(
              path: 'popular',
              builder: (context, state) => const PopularScreen(),
            ),
            GoRoute(
              path: 'favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ]
        ),
        GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen()),
        GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
      ],
    ),

    // --- Detail Routes (Push on top of everything) ---
    GoRoute(
      path: '/product_detail',
      builder: (context, state) => ProductDetailScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/pharmacy_detail',
      builder: (context, state) => PharmacyDetailScreen(pharmacy: state.extra as Pharmacy),
    ),
    GoRoute(
      path: '/category_products',
      builder: (context, state) => CategoryProductsScreen(category: state.extra as Category),
    ),
    GoRoute(
      path: '/related_products',
      builder: (context, state) => RelatedScreen(currentProduct: state.extra as Product),
    ),
    GoRoute(
      path: '/active_ingredient',
      builder: (context, state) => ActiveIngredientScreen(currentProduct: state.extra as Product),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/lastOrder',
      builder: (context, state) => const LastOrderScreen(),
    ),
  ],
);